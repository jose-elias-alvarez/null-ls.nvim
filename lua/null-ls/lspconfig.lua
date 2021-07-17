local config = require("null-ls.config")

local M = {}

function M.setup()
    local configs = require("lspconfig/configs")
    local util = require("lspconfig/util")

    local config_def = {
        cmd = { "nvim" },
        root_dir = vim.fn.getcwd(), -- not relevant yet, but required
        name = "null-ls",
        flags = { debounce_text_changes = config.get().debounce },
    }
    config_def.root_dir = util.root_pattern("Makefile", ".git")
    config_def.filetypes = config.get()._filetypes
    config_def.autostart = false

    configs["null-ls"] = {
        default_config = config_def,
    }

    -- listen on FileType and attach if needed
    vim.cmd([[
      augroup null-ls
        autocmd!
        autocmd FileType * unsilent lua require("null-ls.lspconfig").try_add()
      augroup end
    ]])
end

-- this updates the filetypes on the lspconfig. Only used by LspInfo
function M.on_register_filetypes()
    local nls = require("lspconfig")["null-ls"]
    if nls then
        nls.filetypes = config.get()._filetypes
    end
end

-- this will try to attach to existing buffers and will send a didOpen to trigger diagnostics
function M.on_register_source()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        M.try_add(bufnr)
        vim.lsp.buf_notify(bufnr, "textDocument/didChange", { textDocument = { uri = vim.uri_from_bufnr(bufnr) } })
    end
end

function M.try_add(bufnr)
    local nls = require("lspconfig")["null-ls"]
    if nls and nls.manager then
        bufnr = bufnr or tonumber(vim.fn.expand("<abuf>"))
        local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
        local fts = config.get()._filetypes
        if vim.tbl_contains(fts, ft) or vim.tbl_contains(fts, "*") then
            nls.manager.try_add(bufnr)
        end
    end
end

return M
