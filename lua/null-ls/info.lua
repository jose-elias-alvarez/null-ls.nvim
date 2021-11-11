local methods = require("null-ls.methods")
local u = require("null-ls.utils")
local c = require("null-ls.config")

local lsp = vim.lsp
local api = vim.api

local M = {}

M.get_active_sources = function(bufnr, ft)
    bufnr = bufnr or api.nvim_get_current_buf()
    ft = ft or api.nvim_buf_get_option(bufnr, "filetype")

    local active_sources = {}
    for _, source in ipairs(c.get()._sources) do
        if require("null-ls.sources").is_available(source, ft) then
            for method in pairs(source.methods) do
                active_sources[method] = active_sources[method] or {}
                table.insert(active_sources[method], source.name)
            end
        end
    end
    return active_sources
end

M.show_window = function()
    local windows = require("lspconfig.ui.windows")

    local client = u.get_client()
    local bufnr = api.nvim_get_current_buf()
    if not client or not lsp.buf_is_attached(bufnr, client.id) then
        u.echo("WarningMsg", "failed to get info: buffer is not attached")
        return
    end

    local lines = {}

    local log_path = c.get().debug and require("lspconfig.util").path.join(vim.fn.stdpath("cache"), "null-ls.log")
        or "not enabled (this is normal; see the README if you need to enable logging)"
    table.insert(lines, "null-ls log: " .. log_path)

    local ft = api.nvim_buf_get_option(bufnr, "filetype")
    vim.list_extend(lines, { "Detected filetype: " .. ft, "" })

    local active_sources = M.get_active_sources(bufnr, ft)
    local source_count = 0
    for _, sources in pairs(active_sources) do
        source_count = source_count + #sources
    end

    vim.list_extend(lines, { source_count .. " source(s) active for this buffer:", "" })
    for method, sources in pairs(active_sources) do
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

return M
