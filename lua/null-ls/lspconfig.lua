local methods = require("null-ls.methods")
local sources = require("null-ls.sources")
local c = require("null-ls.config")
local u = require("null-ls.utils")

local api = vim.api

local should_attach = function(bufnr)
    local all_sources = sources.get_all()
    -- don't attach if no sources have been registered
    if vim.tbl_isempty(all_sources) then
        return false
    end

    -- be paranoid and try to make sure that the buffer represents an actual file
    if api.nvim_buf_get_option(bufnr, "buftype") ~= "" or api.nvim_buf_get_name(bufnr) == "" then
        return false
    end

    local ft = api.nvim_buf_get_option(bufnr, "filetype")
    -- writing and immediately deleting a buffer (e.g. :wq from a git commit)
    -- triggers a bug on 0.5.1 which is fixed on master
    if ft == "gitcommit" and not u.has_version("0.6.0") then
        return false
    end

    for _, source in ipairs(all_sources) do
        if sources.is_available(source, ft) then
            return true
        end
    end

    return false
end

local M = {}

function M.setup()
    local lsputil = require("lspconfig.util")
    local default_config = {
        cmd = { "nvim" },
        name = "null-ls",
        root_dir = function(fname)
            return lsputil.root_pattern(".null-ls-root", "Makefile", ".git")(fname) or lsputil.path.dirname(fname)
        end,
        flags = { debounce_text_changes = c.get().debounce },
        filetypes = sources.get_filetypes(),
        autostart = false,
    }

    require("lspconfig/configs")["null-ls"] = {
        default_config = default_config,
    }

    -- listen on FileType and try attaching
    vim.cmd([[
      augroup NullLs
        autocmd!
        autocmd FileType * lua require("null-ls.lspconfig").try_add()
      augroup end
    ]])
end

-- after registering a new source, try attaching to existing buffers and refresh diagnostics
function M.on_register_source(source)
    if not require("lspconfig")["null-ls"] then
        return
    end

    local client = u.get_client()
    if not client then
        return
    end

    local handle_existing_buffer = function(buf)
        M.try_add(buf.bufnr)
        if
            sources.is_available(source, api.nvim_buf_get_option(buf.bufnr, "filetype"), methods.internal.DIAGNOSTICS)
        then
            client.notify(methods.lsp.DID_CHANGE, {
                textDocument = { uri = vim.uri_from_bufnr(buf.bufnr) },
            })
        end
    end

    vim.tbl_map(handle_existing_buffer, vim.fn.getbufinfo({ listed = 1 }))
end

-- refresh filetypes after modifying registered sources
function M.on_register_sources()
    local config = require("lspconfig")["null-ls"]
    if not config then
        return
    end

    config.filetypes = sources.get_filetypes()
end

function M.try_add(bufnr)
    local config = require("lspconfig")["null-ls"]
    if not config and config.manager then
        return
    end

    bufnr = bufnr or api.nvim_get_current_buf()
    if not should_attach(bufnr) then
        return
    end

    config.manager.try_add(bufnr)
end

return M
