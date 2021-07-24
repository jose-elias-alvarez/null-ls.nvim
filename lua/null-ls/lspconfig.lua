local methods = require("null-ls.methods")
local c = require("null-ls.config")

local M = {}

function M.setup()
    local configs = require("lspconfig/configs")
    local util = require("lspconfig/util")

    local config_def = {
        cmd = { "nvim" },
        name = "null-ls",
        root_dir = function(fname)
            return util.root_pattern("Makefile", ".git")(fname) or util.path.dirname(fname)
        end,
        flags = { debounce_text_changes = c.get().debounce },
        filetypes = c.get()._filetypes,
        autostart = false,
    }

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

-- update filetypes shown in :LspInfo
function M.on_register_filetypes()
    local config = require("lspconfig")["null-ls"]
    if not config then
        return
    end

    config.filetypes = c.get()._filetypes
end

-- attach to existing buffers and send a didChange notification to refresh diagnostics
function M.on_register_source()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        M.try_add(bufnr)
        vim.lsp.buf_notify(bufnr, methods.lsp.DID_CHANGE, { textDocument = { uri = vim.uri_from_bufnr(bufnr) } })
    end
end

function M.try_add(bufnr)
    local config = require("lspconfig")["null-ls"]
    if not (config and config.manager) then
        return
    end

    bufnr = bufnr or tonumber(vim.fn.expand("<abuf>"))
    local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
    local fts = c.get()._filetypes
    if vim.tbl_contains(fts, ft) or vim.tbl_contains(fts, "*") then
        config.manager.try_add(bufnr)
    end
end

return M
