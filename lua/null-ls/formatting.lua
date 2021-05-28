local a = require("plenary.async_lib")

local c = require("null-ls.config")
local u = require("null-ls.utils")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

local lsp = vim.lsp
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

local apply_edits = a.async_void(function(params)
    local edits = a.await(generators.run(
                              u.make_params(params, methods.internal.FORMATTING),
                              postprocess))

    local bufnr = params.bufnr
    if api.nvim_buf_get_option(bufnr, "modified") then return end

    -- default handler doesn't accept bufnr, so call util directly
    lsp.util.apply_text_edits(edits, bufnr)

    if not _G._TEST and c.get().save_after_format and bufnr ==
        api.nvim_get_current_buf() then vim.cmd("silent noautocmd :update") end
end)

M.handler = function(method, original_params, _, bufnr)
    if method == methods.lsp.FORMATTING then
        original_params.bufnr = bufnr
        apply_edits(original_params)

        original_params._null_ls_handled = true
    end
end

return M
