local client = require("null-ls.client")
local config = require("null-ls.config")

local M = {}

function M.setup()
    local configs = require("lspconfig/configs")
    local util = require("lspconfig/util")

    local config_def = client.get_client_config()
    config_def.root_dir = util.root_pattern("Makefile", ".git")
    config_def.filetypes = config.get()._filetypes

    configs["null-ls"] = {
        default_config = config_def,
        on_new_config = function(new_config, root_dir)
            print("on_new_config")
            -- state.reset()
        end,
    }
end

return M
