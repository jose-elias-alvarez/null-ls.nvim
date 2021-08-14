local utils = require("null-ls.utils")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

local M = {}

function M.setup()
    -- code action batching is merged into master
    if vim.fn.has("nvim-0.6.0") > 0 then
        return
    end

    M.code_action_handler = M.combine(methods.lsp.CODE_ACTION)
end

-- this will override a handler, batch results and debounce them
function M.combine(method, ms)
    ms = ms or 100
    local orig = vim.lsp.handlers[method]

    local results = {}

    local handler = utils.debounce(ms, function()
        if #results > 0 then
            pcall(orig, nil, nil, results)
            results = {}
        end
    end)

    vim.lsp.handlers[method] = function(_, _, actions)
        vim.list_extend(results, actions or {})
        handler()
    end
    return vim.lsp.handlers[method]
end

M.setup_client = function(client)
    if client._null_ls_setup then
        return
    end

    client.supports_method = function(method)
        local internal_method = methods.map[method]
        if internal_method then
            return generators.can_run(vim.bo.filetype, internal_method)
        end

        return methods.lsp[method] ~= nil
    end

    client._null_ls_setup = true
end

return M
