local c = require("null-ls.config")
local methods = require("null-ls.methods")

local api = vim.api

local M = {}

local get_content_from_params = function(params)
    -- diagnostic notifications will send full buffer content on open and change
    -- so we can avoid unnecessary api calls
    if params.method == methods.lsp.DID_OPEN and params.textDocument and params.textDocument.text then
        return vim.split(params.textDocument.text, "\n")
    end
    if
        params.method == methods.lsp.DID_CHANGE
        and params.contentChanges
        and params.contentChanges[1]
        and params.contentChanges[1].text
    then
        return vim.split(params.contentChanges[1].text, "\n")
    end

    -- for other methods, fall back to manually getting content
    return M.buf.content(params.bufnr)
end

M.echo = function(hlgroup, message)
    api.nvim_echo({ { "null-ls: " .. message, hlgroup } }, true, {})
end

M.debug_log = function(target, force)
    if not c.get().debug and not force then
        return
    end

    if type(target) == "table" then
        print(vim.inspect(target))
    else
        print(target)
    end
end

M.filetype_matches = function(filetypes, ft)
    if not filetypes then
        return true
    end
    return vim.tbl_contains(filetypes, "*") or vim.tbl_contains(filetypes, ft)
end

M.get_client = function()
    for _, client in ipairs(vim.lsp.get_active_clients()) do
        if client.name == "null-ls" then
            return client
        end
    end
end

-- lsp-compatible range is 0-indexed.
-- lua-friendly range is 1-indexed.
M.range = {
    -- transform lua-friendly range to a lsp-compatible shape.
    ---@param range table<"'row'"|"'col'"|"'end_row'"|"'end_col'", number>
    ---@return table<"'start'"|"'end'", table<"'line'"|"'character'", number>>
    to_lsp = function(range)
        local lsp_range = {
            ["start"] = {
                line = range.row - 1,
                character = range.col - 1,
            },
            ["end"] = {
                line = range.end_row - 1,
                character = range.end_col - 1,
            },
        }
        return lsp_range
    end,
    -- transform lsp_range to a lua-friendly shape.
    ---@param lsp_range table<"'start'"|"'end'", table<"'line'"|"'character'", number>>
    ---@return table<"'row'"|"'col'"|"'end_row'"|"'end_col'", number>
    from_lsp = function(lsp_range)
        local range = {
            row = lsp_range["start"].line + 1,
            col = lsp_range["start"].character + 1,
            end_row = lsp_range["end"].line + 1,
            end_col = lsp_range["end"].character + 1,
        }
        return range
    end,
}

M.make_params = function(original_params, method)
    local bufnr = original_params.bufnr
    local lsp_method = original_params.method
    local pos = api.nvim_win_get_cursor(0)
    local content = get_content_from_params(original_params)

    local params = {
        client_id = original_params.client_id,
        content = content,
        lsp_method = lsp_method,
        method = method,
        row = pos[1],
        col = pos[2],
        bufnr = bufnr,
        bufname = api.nvim_buf_get_name(bufnr),
        ft = api.nvim_buf_get_option(bufnr, "filetype"),
        generators = {},
    }

    if original_params.range then
        params.range = M.range.from_lsp(original_params.range)
    end

    return params
end

M.buf = {
    content = function(bufnr, to_string)
        if not bufnr then
            bufnr = api.nvim_get_current_buf()
        end
        local eol = api.nvim_buf_get_option(bufnr, "eol")

        local split = api.nvim_buf_get_lines(bufnr, 0, -1, false)
        if to_string then
            local text = table.concat(split, "\n")
            return eol and text .. "\n" or text
        end

        if eol then
            table.insert(split, "")
        end
        return split
    end,
}

M.string = {
    replace = function(str, original, replacement)
        local found, found_end = string.find(str, original, nil, true)
        if not found then
            return
        end

        if str == original then
            return replacement
        end

        local first_half = string.sub(str, 0, found - 1)
        local second_half = string.sub(str, found_end + 1)

        return first_half .. replacement .. second_half
    end,

    to_number_safe = function(str, default, offset)
        if not str then
            return default
        end

        local number = tonumber(str)
        return offset and number + offset or number
    end,

    to_start_case = function(str)
        return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
    end,
}

M.table = {
    replace = function(tbl, original, replacement)
        local replaced = {}
        for _, v in ipairs(tbl) do
            table.insert(replaced, v == original and replacement or v)
        end
        return replaced
    end,
}

function M.debounce(ms, fn)
    local timer = vim.loop.new_timer()
    return function(...)
        local argv = { ... }
        timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
        end)
    end
end

function M.throttle(ms, fn)
    local timer = vim.loop.new_timer()
    local running = false
    return function(...)
        if not running then
            local argv = { ... }
            local argc = select("#", ...)

            timer:start(ms, 0, function()
                running = false
                pcall(vim.schedule_wrap(fn), unpack(argv, 1, argc))
            end)
            running = true
        end
    end
end

return M
