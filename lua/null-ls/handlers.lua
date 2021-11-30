local methods = require("null-ls.methods")

local M = {}

M.setup_client = function(client)
    if client._null_ls_setup then
        return
    end

    client.supports_method = function(method)
        local internal_method = methods.map[method]
        if internal_method then
            return require("null-ls.generators").can_run(vim.bo.filetype, internal_method)
        end

        return methods.lsp[method] ~= nil
    end

    client._null_ls_setup = true
end

return M
