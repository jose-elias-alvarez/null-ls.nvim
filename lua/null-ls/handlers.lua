local u = require("null-ls.utils")

local methods = require("null-ls.methods")
local code_actions = require("null-ls.code-actions")

local lsp = vim.lsp
local handlers = lsp.handlers
local diagnostics_handler = handlers[methods.DIAGNOSTICS]

local buf_request_original = lsp.buf_request
local execute_command_original = lsp.buf.execute_command

local M = {}
M.NULL_LS_CLIENT_ID = 9999

M.buf_request = function(bufnr, method, original_params, original_handler)
    original_handler = original_handler or handlers[method]

    local handler
    if methods:exists(method) then
        local params = u.make_params(method, bufnr)

        if method == methods.CODE_ACTION then
            handler = function(err, _, actions, client_id, _, config)
                params.actions = actions or {}
                code_actions.handler(params, function(merged)
                    original_handler(err, method, merged, client_id, bufnr,
                                     config)
                end)
            end
        end
    end

    return buf_request_original(bufnr, method, original_params,
                                handler or original_handler)
end

M.execute_command = function(cmd)
    if cmd.command == code_actions.NULL_LS_CODE_ACTION then
        cmd.action()
        return
    end

    execute_command_original(cmd)
end

M.diagnostics = function(params)
    diagnostics_handler(nil, nil, params, M.NULL_LS_CLIENT_ID, nil, {})
end

return M
