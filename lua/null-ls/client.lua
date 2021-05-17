local s = require("null-ls.state")
local handlers = require("null-ls.handlers")

local lsp = vim.lsp
local api = vim.api

local on_init = function(client) handlers.setup_client(client) end

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
                name = "null-ls",
                flags = {debounce_text_changes = 250}
            })

        s.set({client_id = client_id})
    end

    lsp.buf_attach_client(api.nvim_get_current_buf(), s.get().client_id)
end

return M
