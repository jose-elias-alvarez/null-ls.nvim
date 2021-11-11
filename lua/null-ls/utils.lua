local c = require("null-ls.config")
local methods = require("null-ls.methods")

local api = vim.api

local M = {}

local format_line_ending = {
    ["unix"] = "\n",
    ["dos"] = "\r\n",
    ["mac"] = "\r",
}

local get_line_ending = function(bufnr)
    return format_line_ending[api.nvim_buf_get_option(bufnr, "fileformat")] or "\n"
end

local resolve_content = function(params, bufnr)
    -- currently, neovim is hardcoded to use \n in notifications that include file content
    -- so in other cases we get buffer content directly to make sure it's accurate
    if get_line_ending(bufnr) == format_line_ending["unix"] then
        -- diagnostic notifications will send full buffer content on open and change
        -- so we can avoid unnecessary api calls
        if params.method == methods.lsp.DID_OPEN and params.textDocument and params.textDocument.text then
            return M.split_at_newline(params.bufnr, params.textDocument.text)
        end
        if
            params.method == methods.lsp.DID_CHANGE
            and params.contentChanges
            and params.contentChanges[1]
            and params.contentChanges[1].text
        then
            return M.split_at_newline(params.bufnr, params.contentChanges[1].text)
        end
    end

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

M.join_at_newline = function(bufnr, text)
    local line_ending = get_line_ending(bufnr)
    return table.concat(text, line_ending), line_ending
end

M.split_at_newline = function(bufnr, text)
    local line_ending = get_line_ending(bufnr)
    return vim.split(text, line_ending), line_ending
end

M.debug_log = function(...)
    if not c.get().debug then
        return
    end

    require("null-ls.logger").debug(...)
end

M.get_client = function()
    for _, client in ipairs(vim.lsp.get_active_clients()) do
        if client.name == "null-ls" then
            return client
        end
    end
end

M.resolve_handler = function(method)
    local client = M.get_client()
    return client and client.handlers[method] or vim.lsp.handlers[method]
end

M.has_version = function(ver)
    return vim.fn.has("nvim-" .. ver) > 0
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

    if params.lsp_method == methods.lsp.COMPLETION then
        local line = vim.api.nvim_get_current_line()
        local line_to_cursor = line:sub(1, pos[2])
        local regex = vim.regex("\\k*$")

        params.word_to_complete = line:sub(regex:match_str(line_to_cursor) + 1, params.col)
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
        bufnr = bufnr or api.nvim_get_current_buf()

        local eol = api.nvim_buf_get_option(bufnr, "eol")
        local line_ending = get_line_ending(bufnr)

        local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
        if to_string then
            local text = table.concat(lines, line_ending)
            return eol and text .. line_ending or text
        end

        if eol then
            table.insert(lines, "")
        end
        return lines
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
    uniq = function(t)
        local new_table = {}
        local hash = {}
        for _, v in pairs(t) do
            if not hash[v] then
                table.insert(new_table, v)
                hash[v] = true
            end
        end

        return new_table
    end,
}

-- TODO: remove on 0.6.0 release
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
