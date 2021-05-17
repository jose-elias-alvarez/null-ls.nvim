local handlers = require("null-ls.handlers")
local methods = require("null-ls.methods")
local helpers = require("null-ls.helpers")
local sources = require("null-ls.sources")
local builtins = require("null-ls.builtins")
local server = require("null-ls.server")
local client = require("null-ls.client")
local s = require("null-ls.state")

local M = {}

M.register = sources.register
M.methods = methods.internal
M.helpers = helpers
M.builtins = builtins
M.server = server
M.attach = client.attach

M.setup = function() handlers.setup() end

-- TODO: move (currently breaking e2e tests)
vim.api.nvim_exec([[
    augroup NullLsAttach
        autocmd!
        autocmd BufEnter * lua require'null-ls'.attach()
    augroup END
    ]], false)

M.reset = function()
    handlers.reset()
    s.stop_client()
end

return M
