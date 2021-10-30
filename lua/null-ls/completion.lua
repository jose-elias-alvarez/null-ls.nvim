local u = require("null-ls.utils")
local methods = require("null-ls.methods")

local M = {}

M.handler = function(method, original_params, handler)
    local params = u.make_params(original_params, methods.map[method])
    if method == methods.lsp.COMPLETION then
        require("null-ls.generators").run_registered({
            filetype = params.ft,
            method = methods.map[method],
            params = params,
            callback = function(results)
                u.debug_log("received completion results from generators")
                u.debug_log(results)
                if #results == 0 then
                    handler({})
                else
                    for index, item in ipairs(results) do
                        if type(item) == "string" then
                            results[index] = { label = item, insertText = item }
                        end
                    end

                    handler({ isIncomplete = false, items = results })
                end
            end,
        })
        original_params._null_ls_handled = true
    end
end

return M
