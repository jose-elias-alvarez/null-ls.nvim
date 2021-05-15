local a = require("plenary.async_lib")

local s = require("null-ls.state")
local u = require("null-ls.utils")
local methods = require("null-ls.methods")
local sources = require("null-ls.sources")

local NULL_LS_CODE_ACTION = "_null_ls_code_action"

local M = {}
M.NULL_LS_CODE_ACTION = NULL_LS_CODE_ACTION

local postprocess = function(action)
    s.push_action(action)

    action.command = M.NULL_LS_CODE_ACTION
    action.action = nil
end

local get_actions = a.async_void(function(params, callback)
    s.clear_actions()

    local actions = a.await(sources.run_generators(params, postprocess))
    callback(actions)
end)

M.handler = function(method, params, handler, bufnr)
    if method == methods.CODE_ACTION then
        get_actions(u.make_params(method, bufnr), function(actions)
            handler(nil, method, actions, s.get().client_id, bufnr)
        end)

        params._null_ls_handled = true
    end

    if method == methods.EXECUTE_COMMAND and params.command ==
        NULL_LS_CODE_ACTION then
        s.run_action(params.title)

        params._null_ls_handled = true
    end
end

return M
