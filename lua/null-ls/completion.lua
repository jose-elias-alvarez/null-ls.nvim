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
                    local items = {}
                    local isIncomplete = false
                    for _, result in ipairs(results) do
                        isIncomplete = isIncomplete or result.isIncomplete

                        vim.validate({
                            items = { result.items, "table" },
                            isIncomplete = { result.isIncomplete, "boolean" },
                        })
                        for index, item in ipairs(result.items) do
                            if type(item) == "string" then
                                result.items[index] = { label = item, insertText = item }
                            else
                                vim.validate({
                                    item = { item, "table" },
                                })
                                break
                            end
                        end

                        u.table.extend(items, result.items)
                    end

                    handler({ isIncomplete = isIncomplete, items = items })
                end
            end,
        })
        original_params._null_ls_handled = true
    end
end

return M
