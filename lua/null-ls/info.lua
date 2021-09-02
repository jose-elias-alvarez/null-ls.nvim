local methods = require("null-ls.methods")
local u = require("null-ls.utils")
local c = require("null-ls.config")

local lsp = vim.lsp
local api = vim.api

return function()
    local windows = require("lspconfig.ui.windows")

    local client = u.get_client()

    local bufnr = api.nvim_get_current_buf()
    if not client or not lsp.buf_is_attached(bufnr, client.id) then
        u.echo("WarningMsg", "failed to get info: buffer is not attached")
        return
    end

    local lines = {}

    local separator = vim.loop.os_uname().version:match("Windows") and "\\" or "/"
    local log_path = vim.fn.stdpath("cache") .. separator .. "null-ls.log"
    table.insert(lines, "null-ls log: " .. log_path)

    local ft = api.nvim_buf_get_option(bufnr, "filetype")
    vim.list_extend(lines, { "Detected filetype: " .. ft, "" })

    local registered, source_count = {}, 0
    for method, source in pairs(c.get()._methods) do
        for name, filetypes in pairs(source) do
            if u.filetype_matches(filetypes, ft) then
                registered[method] = registered[method] or {}
                table.insert(registered[method], name)
                source_count = source_count + 1
            end
        end
    end

    vim.list_extend(lines, { source_count .. " source(s) active for this buffer:", "" })
    for method, sources in pairs(registered) do
        table.insert(lines, methods.readable[method] .. ": " .. table.concat(sources, ", "))
    end

    local win_info = windows.percentage_range_window(0.8, 0.7)
    local win_bufnr, win_id = win_info.bufnr, win_info.win_id

    api.nvim_buf_set_lines(win_bufnr, 0, -1, true, lines)
    api.nvim_buf_set_option(win_bufnr, "buftype", "nofile")
    api.nvim_buf_set_option(win_bufnr, "filetype", "null-ls-info")
    api.nvim_buf_set_option(win_bufnr, "modifiable", false)

    api.nvim_buf_set_keymap(win_bufnr, "n", "<Esc>", "<cmd>bd<CR>", { noremap = true })
    lsp.util.close_preview_autocmd({ "BufHidden", "BufLeave" }, win_id)
end
