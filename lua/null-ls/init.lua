local handlers = require("null-ls.handlers")
local autocommands = require("null-ls.autocommands")
local methods = require("null-ls.methods")
local helpers = require("null-ls.helpers")
local builtins = require("null-ls.builtins")
local server = require("null-ls.server")
local client = require("null-ls.client")
local config = require("null-ls.config")

local M = {}

M.register = config.register
M.methods = methods.internal
M.generator = helpers.generator_factory
M.builtins = builtins
M.start_server = server.start
M.try_attach = client.try_attach

M.setup = function(user_config)
    config.setup(user_config or {})

    autocommands.setup()
    handlers.setup()
end

return M
