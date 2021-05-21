local a = require("plenary.async_lib")

local u = require("null-ls.utils")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

local api = vim.api

local M = {}

local postprocess = function(edit)
    edit.range = {
        start = {
            line = u.string.to_number_safe(edit.row, 0),
            character = u.string.to_number_safe(edit.col, 0)
        },
        ["end"] = {
            line = u.string.to_number_safe(edit.end_row, edit.row),
            character = u.string.to_number_safe(edit.end_col, -1)
        }
    }
    edit.newText = edit.text
end

local apply_edits = a.async_void(function(params, callback)
    local edits = a.await(generators.run(
                              u.make_params(params, methods.internal.FORMATTING),
                              postprocess))

    local bufnr = params.bufnr
    if not api.nvim_buf_get_option(bufnr, "modified") then
        callback(edits)
        if bufnr == api.nvim_get_current_buf() then
            vim.cmd("noautocmd :update")
        end
    end
end)

M.handler = function(method, original_params, handler, bufnr)
    if method == methods.lsp.FORMATTING then
        original_params.bufnr = bufnr
        apply_edits(original_params,
                    function(edits) handler(nil, nil, edits) end)

        original_params._null_ls_handled = true
    end
end

return M
