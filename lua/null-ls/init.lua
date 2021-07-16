local methods = require("null-ls.methods")
local helpers = require("null-ls.helpers")
local builtins = require("null-ls.builtins")
local config = require("null-ls.config")

local M = {}

M.register = config.register
M.is_registered = config.is_registered
M.methods = methods.internal
M.generator = helpers.generator_factory
M.formatter = helpers.formatter_factory
M.builtins = builtins

M.config = function(user_config)
    if vim.g.null_ls_disable then
        return
    end
    config.setup(user_config or {})
    require("null-ls.rpc").setup()
    require("null-ls.lspconfig").setup()
end

M.setup = function(user_config)
    user_config = user_config or {}
    M.config(user_config)
    require("lspconfig")["null-ls"].setup({ on_attach = user_config.on_attach })
end

return M
