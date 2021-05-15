local s = require("null-ls.state")
local diagnostics = require("null-ls.diagnostics")
local handlers = require("null-ls.handlers")

local lsp = vim.lsp
local api = vim.api

local on_init = function(client)
    handlers.setup_client(client)
    lsp.buf_attach_client(api.nvim_get_current_buf(), s.get().client_id)
end

local on_attach = function(_, bufnr) diagnostics.attach(bufnr) end
local on_detach = function() diagnostics._reset() end

local M = {}
M.attach = function()
    if not s.get().client_id then
        local client_id = lsp.start_client(
                              {
                cmd = {
                    "nvim", "--headless", "--noplugin", "-c",
                    "lua require'null-ls'.server()"
                },
                root_dir = vim.fn.getcwd(),
                on_init = on_init,
                on_attach = on_attach,
                on_detach = on_detach,
                name = "null-ls"
            })
        s.set({client_id = client_id})
        return
    end

    lsp.buf_attach_client(api.nvim_get_current_buf(), s.get().client_id)
end

return M
