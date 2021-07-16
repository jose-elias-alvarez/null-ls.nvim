local utils = require("null-ls.utils")

local M = {}

function M.setup()
    M.code_action_handler = M.combine("textDocument/codeAction")
end

-- this will override a handler, batch results and debounce them
function M.combine(method, ms)
    ms = ms or 100
    local orig = vim.lsp.handlers[method]

    local results = {}

    local handler = utils.debounce(ms, function()
        if #results > 0 then
            orig(nil, nil, results)
            results = {}
        end
    end)

    vim.lsp.handlers[method] = function(_, _, actions)
        vim.list_extend(results, actions or {})
        handler()
    end
    return vim.lsp.handlers[method]
end

return M
