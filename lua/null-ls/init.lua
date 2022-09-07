local c = require("null-ls.config")
local helpers = require("null-ls.helpers")
local sources = require("null-ls.sources")

local M = {}

M.deregister = sources.deregister
M.disable = sources.disable
M.enable = sources.enable
M.get_source = sources.get
M.get_sources = sources.get_all
M.is_registered = sources.is_registered
M.register = sources.register
M.register_name = sources.register_name
M.reset_sources = sources.reset
M.toggle = sources.toggle

M.builtins = require("null-ls.builtins")
M.methods = require("null-ls.methods").internal

M.formatter = helpers.formatter_factory
M.generator = helpers.generator_factory

M.setup = function(user_config)
    if c.get()._setup then
        return
    end

    user_config = user_config or {}
    c.setup(user_config)

    vim.api.nvim_create_user_command("NullLsInfo", function()
        require("null-ls.info").show_window()
    end, {})
    vim.api.nvim_create_user_command("NullLsLog", function()
        vim.cmd(string.format("edit %s", require("null-ls.logger"):get_path()))
    end, {})

    local augroup = vim.api.nvim_create_augroup("NullLs", {})
    vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        callback = function()
            require("null-ls.client").try_add()
        end,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
        group = augroup,
        callback = function()
            require("null-ls.rpc").flush()
        end,
    })
end

return M
