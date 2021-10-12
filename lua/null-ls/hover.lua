local u = require("null-ls.utils")
local methods = require("null-ls.methods")

local M = {}

M.handler = function(method, original_params, handler)
    local params = u.make_params(original_params, methods.map[method])
    if method == methods.lsp.HOVER then
        require("null-ls.generators").run_registered({
            filetype = params.ft,
            method = methods.map[method],
            params = params,
            callback = function(results)
                u.debug_log("received hover results from generators")
                u.debug_log(results)
                handler({ contents = { results } })
            end,
        })
        original_params._null_ls_handled = true
    end
end

return M
