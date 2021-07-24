local methods = require("null-ls.methods")
local c = require("null-ls.config")
local u = require("null-ls.utils")

local api = vim.api

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

    -- listen on FileType and try attaching
    vim.cmd([[
      augroup NullLs
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

    bufnr = bufnr or api.nvim_get_current_buf()
    local ft, buftype = api.nvim_buf_get_option(bufnr, "filetype"), api.nvim_buf_get_option(bufnr, "buftype")
    -- lspconfig checks if buftype == "nofile", but we want to be defensive, since (if configured) null-ls will try attaching to any buffer
    if buftype ~= "" or not u.filetype_matches(c.get()._filetypes, ft) then
        return
    end

    config.manager.try_add(bufnr)
end

return M
