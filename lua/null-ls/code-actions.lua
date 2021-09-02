local s = require("null-ls.state")
local u = require("null-ls.utils")
local methods = require("null-ls.methods")

local M = {}

local postprocess = function(action)
    s.register_action(action)

    action.command = methods.internal.CODE_ACTION
    action.action = nil
end

M.handler = function(method, original_params, handler)
    if method == methods.lsp.CODE_ACTION then
        if not original_params.textDocument then
            return
        end
        if original_params._null_ls_ignore then
            return
        end

        s.clear_actions()
        local params = u.make_params(original_params, methods.map[method])
        require("null-ls.generators").run_registered({
            filetype = params.ft,
            method = methods.map[method],
            params = params,
            postprocess = postprocess,
            callback = function(actions)
                u.debug_log("received code actions from generators")
                u.debug_log(actions)

                -- sort actions by title
                table.sort(actions, function(a, b)
                    return a.title < b.title
                end)
                handler(actions)
            end,
        })
        original_params._null_ls_handled = true
    end

    if method == methods.lsp.EXECUTE_COMMAND and original_params.command == methods.internal.CODE_ACTION then
        s.run_action(original_params.title)
        original_params._null_ls_handled = true
    end
end

return M
