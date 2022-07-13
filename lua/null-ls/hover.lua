local u = require("null-ls.utils")
local methods = require("null-ls.methods")
local log = require("null-ls.logger")

local M = {}

M.handler = function(method, original_params, handler)
    local params = u.make_params(original_params, methods.map[method])
    if method == methods.lsp.HOVER then
        require("null-ls.generators").run_registered({
            filetype = params.ft,
            method = methods.map[method],
            params = params,
            callback = function(results)
                log:trace("received hover results from generators")
                log:trace(vim.inspect(results))
                handler({ contents = { results } })
            end,
        })
        original_params._null_ls_handled = true
    end
end

return M
