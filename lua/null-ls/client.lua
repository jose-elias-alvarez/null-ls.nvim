local s = require("null-ls.state")
local c = require("null-ls.config")
local handlers = require("null-ls.handlers")

local lsp = vim.lsp
local api = vim.api

local on_init = function(client)
    handlers.setup_client(client)

    s.set({initialized = true})
end

-- set false (as opposed to nil) to allow waiting for client exit
local on_exit = function() s.set({initialized = false}) end

local start_client = function()
    s.reset()

    local client_id = lsp.start_client({
        cmd = {
            "nvim", "--headless", "-u", "NONE", "-c",
            "lua require'null-ls'.start_server()"
        },
        root_dir = vim.fn.getcwd(), -- not relevant yet, but required
        on_init = on_init,
        on_exit = on_exit,
        on_attach = c.get().on_attach,
        name = "null-ls",
        flags = {debounce_text_changes = c.get().debounce}
    })

    s.set({client_id = client_id})
end

local M = {}

M.start = start_client

M.try_attach = function()
    local bufnr = api.nvim_get_current_buf()
    if vim.fn.buflisted(bufnr) == 0 then return end

    -- the event that triggers this function must fire after the buffer's filetype has been set
    local ft = api.nvim_buf_get_option(bufnr, "filetype")
    if not vim.tbl_contains(c.get().filetypes, ft) then return end

    if not s.get().client_id then start_client() end

    s.attach(bufnr)
end

return M
