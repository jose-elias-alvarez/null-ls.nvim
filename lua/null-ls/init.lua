local helpers = require("null-ls.helpers")
local sources = require("null-ls.sources")
local c = require("null-ls.config")

local M = {}

M.get_sources = sources.get_all
M.get_source = sources.get
M.register = sources.register
M.disable = sources.disable
M.enable = sources.enable
M.toggle = sources.toggle
M.deregister = sources.deregister
M.reset_sources = sources.reset
M.is_registered = sources.is_registered
M.register_name = sources.register_name

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

    vim.cmd("command! NullLsInfo lua require('null-ls').null_ls_info()")
    vim.cmd("command! NullLsLog lua vim.fn.execute('edit ' .. require('null-ls.logger').get_path())")

    vim.cmd([[
      augroup NullLs
        autocmd!
        autocmd FileType * lua require("null-ls.client").try_add()
        autocmd InsertLeave * unsilent lua require("null-ls.rpc").flush()
      augroup end
    ]])
end

return M
