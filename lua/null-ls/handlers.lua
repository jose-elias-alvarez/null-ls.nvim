local u = require("null-ls.utils")
local methods = require("null-ls.methods")

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
    local orig = u.resolve_handler(method)
    local is_new = vim.fn.has("nvim-0.5.1") > 0

    local all_results = {}

    local handler = u.debounce(ms, function()
        if #all_results > 0 then
            if is_new then
                pcall(orig, nil, all_results)
            else
                pcall(orig, nil, nil, all_results)
            end
            all_results = {}
        end
    end)

    if is_new then
        vim.lsp.handlers[method] = function(_, results)
            vim.list_extend(all_results, results or {})
            handler()
        end
    else
        vim.lsp.handlers[method] = function(_, _, results)
            vim.list_extend(all_results, results or {})
            handler()
        end
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
            return require("null-ls.generators").can_run(vim.bo.filetype, internal_method)
        end

        return methods.lsp[method] ~= nil
    end

    client._null_ls_setup = true
end

return M
