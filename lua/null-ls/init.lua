local handlers = require("null-ls.handlers")
local autocommands = require("null-ls.autocommands")
local methods = require("null-ls.methods")
local helpers = require("null-ls.helpers")
local builtins = require("null-ls.builtins")
local server = require("null-ls.server")
local client = require("null-ls.client")
local config = require("null-ls.config")
local s = require("null-ls.state")

local M = {}

M.register = config.register
M.is_registered = config.is_registered
M.methods = methods.internal
M.generator = helpers.generator_factory
M.formatter = helpers.formatter_factory
M.builtins = builtins
M.start_server = server.start
M.try_attach = client.try_attach
M.attach_or_refresh = client.attach_or_refresh

M.shutdown = function()
    handlers.reset()
    config.reset()
    autocommands.reset()

    s.shutdown_client()
end

M.disable = function()
    vim.g.null_ls_disable = true
    M.shutdown()
end

M.config = function(user_config)
    if vim.g.null_ls_disable then
        return
    end
    config.setup(user_config or {})
    require("null-ls.lspconfig").setup()
end

M.setup = function(user_config)
    user_config = user_config or {}
    M.config(user_config)
    require("lspconfig")["null-ls"].setup({ on_attach = user_config.on_attach })
end

return M
