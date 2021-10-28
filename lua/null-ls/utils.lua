local c = require("null-ls.config")
local methods = require("null-ls.methods")

local api = vim.api

local M = {}

local resolve_content = function(params, bufnr)
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
    return M.buf.content(bufnr)
end

local resolve_bufnr = function(params)
    -- if already set, do nothing
    if params.bufnr then
        return params.bufnr
    end

    -- get from uri
    if params.textDocument and params.textDocument.uri then
        return vim.uri_to_bufnr(params.textDocument.uri)
    end

    -- fallback
    return api.nvim_get_current_buf()
end

M.echo = function(hlgroup, message)
    api.nvim_echo({ { "null-ls: " .. message, hlgroup } }, true, {})
end

M.debug_log = function(...)
    if not c.get().debug then
        return
    end

    require("null-ls.logger").debug(...)
end

M.filetype_matches = function(filetypes, ft)
    -- simple list of enabled filetypes, e.g. { "lua", "tl" }
    if vim.tbl_islist(filetypes) then
        return vim.tbl_isempty(filetypes) or vim.tbl_contains(filetypes, ft)
    end

    -- allow specifically disabling filetypes with a table, e.g. { lua = "false" }
    for key, val in pairs(filetypes) do
        if key == ft and val == false then
            return false
        end
    end

    return true
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
                line = range.row >= 1 and range.row - 1 or 0,
                character = range.col >= 1 and range.col - 1 or 0,
            },
            ["end"] = {
                line = range.end_row >= 1 and range.end_row - 1 or 0,
                character = range.end_col >= 1 and range.end_col - 1 or 0,
            },
        }
        return lsp_range
    end,
    -- transform lsp_range to a lua-friendly shape.
    ---@param lsp_range table<"'start'"|"'end'", table<"'line'"|"'character'", number>>
    ---@return table<"'row'"|"'col'"|"'end_row'"|"'end_col'", number>
    from_lsp = function(lsp_range)
        local start_range = lsp_range["start"]
        local end_range = lsp_range["end"]
        local range = {
            row = start_range.line >= 0 and start_range.line + 1 or 1,
            col = start_range.character >= 0 and start_range.character + 1 or 1,
            end_row = end_range.line >= 0 and end_range.line + 1 or 1,
            end_col = end_range.character >= 0 and end_range.character + 1 or 1,
        }
        return range
    end,
}

M.make_params = function(original_params, method)
    local bufnr = resolve_bufnr(original_params)
    local content = resolve_content(original_params, bufnr)
    local pos = api.nvim_win_get_cursor(0)

    local params = {
        client_id = original_params.client_id,
        lsp_method = original_params.method,
        content = content,
        method = method,
        row = pos[1],
        col = pos[2],
        bufnr = bufnr,
        bufname = api.nvim_buf_get_name(bufnr),
        ft = api.nvim_buf_get_option(bufnr, "filetype"),
    }

    if original_params.range then
        params.range = M.range.from_lsp(original_params.range)
    end

    return params
end

M.make_conditional_utils = function()
    local lsputil = require("lspconfig.util")
    local cwd = vim.loop.cwd()

    return {
        root_has_file = function(name)
            return lsputil.path.exists(lsputil.path.join(cwd, name))
        end,
        root_matches = function(pattern)
            return cwd:find(pattern) ~= nil
        end,
    }
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

M.table = {
    replace = function(tbl, original, replacement)
        local replaced = {}
        for _, v in ipairs(tbl) do
            table.insert(replaced, v == original and replacement or v)
        end
        return replaced
    end,
}

M.resolve_handler = function(method)
    local client = M.get_client()
    return client and client.handlers[method] or vim.lsp.handlers[method]
end

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
