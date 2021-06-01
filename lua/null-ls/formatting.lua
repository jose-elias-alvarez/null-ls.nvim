local a = require("plenary.async_lib")

local s = require("null-ls.state")
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
            character = u.string.to_number_safe(edit.col, 0),
        },
        ["end"] = {
            line = u.string.to_number_safe(edit.end_row, edit.row),
            character = u.string.to_number_safe(edit.end_col, -1),
        },
    }
    edit.newText = edit.text
end

local apply_edits = a.async_void(function(params, handler)
    local edits = a.await(generators.run(u.make_params(params, methods.internal.FORMATTING), postprocess))

    local bufnr = params.bufnr
    if not api.nvim_buf_get_option(bufnr, "modified") then
        -- default handler doesn't accept bufnr, so call util directly
        lsp.util.apply_text_edits(edits, bufnr)

        if c.get().save_after_format and not _G._TEST then
            vim.cmd(bufnr .. "bufdo silent noautocmd update")
        end
    end

    -- call original handler with empty response so buf.request_sync() doesn't time out
    handler(nil, methods.lsp.FORMATTING, {}, s.get().client_id, bufnr)
end)

M.handler = function(method, original_params, handler, bufnr)
    if method == methods.lsp.FORMATTING then
        original_params.bufnr = bufnr
        apply_edits(original_params, handler)

        original_params._null_ls_handled = true
    end
end

return M
