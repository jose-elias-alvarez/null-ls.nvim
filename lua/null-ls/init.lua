local helpers = require("null-ls.helpers")
local c = require("null-ls.config")

local M = {}

M.register = c.register
M.is_registered = c.is_registered
M.register_name = c.register_name

M.methods = require("null-ls.methods").internal
M.builtins = require("null-ls.builtins")
M.null_ls_info = require("null-ls.info").show_window

M.generator = helpers.generator_factory
M.formatter = helpers.formatter_factory

M.config = function(user_config)
    if vim.g.null_ls_disable or c.get()._setup then
        return
    end

    c.setup(user_config or {})
    require("null-ls.rpc").setup()
    require("null-ls.lspconfig").setup()
    require("null-ls.handlers").setup()

    vim.cmd("command! NullLsInfo lua require('null-ls').null_ls_info()")
end

return M
