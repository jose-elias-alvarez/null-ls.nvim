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

M.join_at_newline = function(bufnr, text)
    local line_ending = get_line_ending(bufnr)
    return table.concat(text, line_ending), line_ending
end

M.split_at_newline = function(bufnr, text)
    local line_ending = get_line_ending(bufnr)
    return vim.split(text, line_ending), line_ending
end

M.has_version = function(ver)
    return vim.fn.has("nvim-" .. ver) > 0
end

M.is_executable = function(cmd)
    local is_executable = vim.fn.executable(cmd) > 0
    if is_executable then
        return true
    end

    return false, string.format("command %s is not executable (make sure it's installed and on your $PATH)", cmd)
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
        options = original_params.options,
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
        local line = params.content[params.row]
        local line_to_cursor = line:sub(1, pos[2])
        local regex = vim.regex("\\k*$")

        params.word_to_complete = line:sub(regex:match_str(line_to_cursor) + 1, params.col)
    end

    return params
end

M.make_conditional_utils = function()
    local root = M.get_root()

    return {
        root_has_file = function(...)
            local patterns = vim.tbl_flatten({ ... })
            for _, name in ipairs(patterns) do
                if M.path.exists(M.path.join(root, name)) then
                    return true
                end
            end
            return false
        end,
        root_matches = function(pattern)
            return root:find(pattern) ~= nil
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
    for_each_bufnr = function(cb)
        for _, bufnr in ipairs(api.nvim_list_bufs()) do
            if api.nvim_buf_is_loaded(bufnr) then
                cb(bufnr)
            end
        end
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

M.handle_function_opt = function(opt, ...)
    if type(opt) == "function" then
        return opt(...)
    end

    return vim.deepcopy(opt)
end

M.get_root = function()
    local root

    -- prefer getting from client
    local client = require("null-ls.client").get_client()
    if client then
        root = client.config.root_dir
    end

    -- if in named buffer, resolve directly from root_dir
    if not root then
        local fname = api.nvim_buf_get_name(0)
        if fname ~= "" then
            root = require("null-ls.config").get().root_dir(fname)
        end
    end

    -- fall back to cwd
    root = root or vim.loop.cwd()

    return root
end

-- everything below is adapted from nvim-lspconfig's path utils
M.path = (function()
    local exists = function(filename)
        local stat = vim.loop.fs_stat(filename)
        return stat ~= nil
    end

    local is_windows = vim.loop.os_uname().version:match("Windows")
    local path_separator = is_windows and "\\" or "/"

    local is_fs_root
    if is_windows then
        is_fs_root = function(path)
            return path:match("^%a:$")
        end
    else
        is_fs_root = function(path)
            return path == "/"
        end
    end

    local dirname
    do
        local strip_dir_pattern = path_separator .. "([^" .. path_separator .. "]+)$"
        local strip_separator_pattern = path_separator .. "$"
        dirname = function(path)
            if not path or #path == 0 then
                return
            end
            local result = path:gsub(strip_separator_pattern, ""):gsub(strip_dir_pattern, "")
            if #result == 0 then
                return "/"
            end
            return result
        end
    end

    local path_join = function(...)
        local result = table.concat(vim.tbl_flatten({ ... }), path_separator):gsub(
            path_separator .. "+",
            path_separator
        )
        return result
    end

    local traverse_parents = function(path, cb)
        path = vim.loop.fs_realpath(path)
        local dir = path
        -- guard against infinite loop
        for _ = 1, 100 do
            dir = dirname(dir)
            if not dir then
                return
            end

            if cb(dir, path) then
                return dir, path
            end

            if is_fs_root(dir) then
                break
            end
        end
    end

    -- iterate path until root dir is found
    local iterate_parents = function(path)
        local function it(_, v)
            if v and not is_fs_root(v) then
                v = dirname(v)
            else
                return
            end
            if v and vim.loop.fs_realpath(v) then
                return v, path
            else
                return
            end
        end
        return it, path, path
    end

    return {
        is_windows = is_windows,
        exists = exists,
        dirname = dirname,
        join = path_join,
        traverse_parents = traverse_parents,
        iterate_parents = iterate_parents,
    }
end)()

M.search_ancestors = function(startpath, f)
    if f(startpath) then
        return startpath
    end
    local guard = 100
    for path in M.path.iterate_parents(startpath) do
        -- prevent infinite recursion
        guard = guard - 1
        if guard == 0 then
            return
        end

        if f(path) then
            return path
        end
    end
end

M.root_pattern = function(...)
    local patterns = vim.tbl_flatten({ ... })
    local function matcher(path)
        -- Escape wildcard characters in the path so that it itself is not treated like a glob.
        path = vim.fn.escape(path, "?*[]")

        for _, pattern in ipairs(patterns) do
            for _, p in ipairs(vim.fn.glob(M.path.join(path, pattern), true, true)) do
                if M.path.exists(p) then
                    return path
                end
            end
        end
    end

    return function(startpath)
        return M.search_ancestors(startpath, matcher)
    end
end

return M
