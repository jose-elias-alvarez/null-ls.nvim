local a = require("plenary.async_lib")
local sources = require("null-ls.sources")

local M = {}
M.NULL_LS_CODE_ACTION = "_null_ls_code_action"

local postprocess = function(action) action.command = M.NULL_LS_CODE_ACTION end

M.handler = a.async_void(function(params, callback)
    local actions = a.await(sources.run_generators(params, postprocess))
    callback(vim.list_extend(params.actions, actions))
end)

return M
