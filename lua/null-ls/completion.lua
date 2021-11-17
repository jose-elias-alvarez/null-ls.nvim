local u = require("null-ls.utils")
local methods = require("null-ls.methods")
local log = require("null-ls.logger")

local M = {}

M.handler = function(method, original_params, handler)
    local params = u.make_params(original_params, methods.map[method])
    if method == methods.lsp.COMPLETION then
        require("null-ls.generators").run_registered({
            filetype = params.ft,
            method = methods.map[method],
            params = params,
            callback = function(results)
                if #results == 0 then
                    log:debug("received no completion results from generators")
                    handler({})
                else
                    log:debug("received completion results from generators")
                    log:trace(vim.inspect(results))
                    local items = {}
                    local isIncomplete = false
                    for _, result in ipairs(results) do
                        isIncomplete = isIncomplete or result.isIncomplete

                        vim.list_extend(items, result.items)
                    end

                    handler({ isIncomplete = isIncomplete, items = items })
                end
            end,
        })
        original_params._null_ls_handled = true
    end
end

return M
