local api = vim.api

local M = {}

M.echo = function(hlgroup, message)
    api.nvim_echo({{"null-ls: " .. message, hlgroup}}, true, {})
end

M.filetype_matches = function(handler, ft)
    return not handler.filetypes or vim.tbl_contains(handler.filetypes, ft)
end

M.make_params = function(method, bufnr)
    if not bufnr then bufnr = api.nvim_get_current_buf() end

    local pos = api.nvim_win_get_cursor(0)
    return {
        method = method,
        row = pos[1],
        col = pos[2],
        bufnr = bufnr,
        bufname = api.nvim_buf_get_name(bufnr),
        uri = vim.uri_from_bufnr(bufnr),
        content = M.buf.content(bufnr),
        ft = vim.bo.filetype
    }
end

M.buf = {
    content = function(bufnr, to_string)
        if not bufnr then bufnr = api.nvim_get_current_buf() end

        local split = api.nvim_buf_get_lines(bufnr, 0, -1, false)
        if to_string then return table.concat(split, "\n") .. "\n" end

        table.insert(split, "\n")
        return split
    end
}

M.string = {
    replace = function(str, original, replacement)
        local found, found_end = string.find(str, original, nil, true)
        if not found then return end

        if str == original then return replacement end

        local first_half = string.sub(str, 0, found - 1)
        local second_half = string.sub(str, found_end + 1)

        return first_half .. replacement .. second_half
    end,

    to_number_safe = function(str, default, offset)
        if not str then return default end

        local number = tonumber(str)
        return offset and number + offset or number
    end
}

return M
