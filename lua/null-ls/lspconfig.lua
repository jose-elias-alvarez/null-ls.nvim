local config = require("null-ls.config")

local M = {}

function M.setup()
    local configs = require("lspconfig/configs")
    local util = require("lspconfig/util")

    local config_def = {
        cmd = { "nvim" },
        root_dir = vim.fn.getcwd(), -- not relevant yet, but required
        name = "null-ls",
        flags = { debounce_text_changes = config.get().debounce },
    }
    config_def.root_dir = util.root_pattern("Makefile", ".git")
    config_def.filetypes = config.get()._filetypes

    configs["null-ls"] = {
        default_config = config_def,
    }
end

return M
