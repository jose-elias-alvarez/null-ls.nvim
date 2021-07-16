local u = require("null-ls.utils")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")
local c = require("null-ls.config")

local lsp = vim.lsp
local api = vim.api

local M = {}

local save_win_data = function(bufnr)
    local marks = {}
    for _, m in pairs(vim.fn.getmarklist(bufnr)) do
        if m.mark:match("%a") then
            marks[m.mark] = m.pos
        end
    end

    local views = {}
    for _, win in pairs(vim.api.nvim_list_wins()) do
        views[win] = api.nvim_win_call(win, function()
            return vim.fn.winsaveview()
        end)
    end

    return marks, views
end

local restore_win_data = function(marks, views, bufnr)
    -- no need to restore marks that still exist
    for _, m in pairs(vim.fn.getmarklist(bufnr)) do
        marks[m.mark] = nil
    end
    for mark, pos in pairs(marks) do
        if pos then
            vim.fn.setpos(mark, pos)
        end
    end

    for win, view in pairs(views) do
        api.nvim_win_call(win, function()
            vim.fn.winrestview(view)
        end)
    end
end

M.handler = function(method, original_params, handler)
    if not original_params.textDocument then
        return
    end
    local uri = original_params.textDocument.uri
    local bufnr = vim.uri_to_bufnr(uri)

    local apply_edits = function(edits, params)
        u.debug_log("received edits from generators")
        u.debug_log(edits)

        local diffed_edits = {}
        for _, edit in ipairs(edits) do
            local diffed = lsp.util.compute_diff(params.content, vim.split(edit.text, "\n"))
            table.insert(diffed_edits, { newText = diffed.text, range = diffed.range })
        end

        local marks, views = save_win_data(bufnr)

        handler(diffed_edits)

        vim.defer_fn(function()
            restore_win_data(marks, views, bufnr)
            if c.get().save_after_format and not _G._TEST then
                vim.cmd(bufnr .. "bufdo! silent keepjumps noautocmd update")
            end
        end, 0)

        u.debug_log("successfully applied edits")
    end

    if method == methods.lsp.FORMATTING then
        u.debug_log("received LSP formatting request")

        original_params.bufnr = bufnr
        generators.run(u.make_params(original_params, methods.internal.FORMATTING), nil, apply_edits)

        original_params._null_ls_handled = true
    end

    if method == methods.lsp.RANGE_FORMATTING then
        u.debug_log("received LSP rangeFormatting request")

        original_params.bufnr = bufnr
        generators.run(u.make_params(original_params, methods.internal.RANGE_FORMATTING), nil, apply_edits)

        original_params._null_ls_handled = true
    end
end

return M
