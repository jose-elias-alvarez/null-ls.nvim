local s = require("null-ls.state")
local c = require("null-ls.config")
local u = require("null-ls.utils")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

local lsp = vim.lsp
local api = vim.api

local M = {}

local save_win_data = function(bufnr, winid)
    local marks = {}
    for _, m in pairs(vim.fn.getmarklist(bufnr)) do
        if m.mark:match("%a") then
            marks[m.mark] = m.pos
        end
    end

    vim.cmd("windo let w:null_ls_view=winsaveview()")
    api.nvim_set_current_win(winid)

    return marks
end

local restore_win_data = function(marks, bufnr, winid)
    -- no need to restore marks that still exist
    for _, m in pairs(vim.fn.getmarklist(bufnr)) do
        marks[m.mark] = nil
    end
    for mark, pos in pairs(marks) do
        if pos then
            vim.fn.setpos(mark, pos)
        end
    end

    vim.cmd("windo call winrestview(w:null_ls_view)")
    api.nvim_set_current_win(winid)
end

M.handler = function(method, original_params, handler, bufnr)
    local apply_edits = function(edits, params)
        u.debug_log("received edits from generators")
        u.debug_log(edits)

        local diffed_edits = {}
        for _, edit in ipairs(edits) do
            local diffed = lsp.util.compute_diff(params.content, vim.split(edit.text, "\n"))
            table.insert(diffed_edits, { newText = diffed.text, range = diffed.range })
        end

        local winid = api.nvim_get_current_win()
        local marks = save_win_data(bufnr, winid)

        -- default handler doesn't accept bufnr, so call util directly
        lsp.util.apply_text_edits(diffed_edits, bufnr)
        restore_win_data(marks, bufnr, winid)

        if c.get().save_after_format and not _G._TEST then
            local current_bufnr = api.nvim_win_get_buf(0)
            vim.cmd(bufnr .. "bufdo! silent keepjumps noautocmd update")

            if current_bufnr ~= bufnr then
                api.nvim_win_set_buf(0, current_bufnr)
            end
        end

        -- call original handler with empty response so buf.request_sync() doesn't time out
        handler(nil, method, {}, s.get().client_id, bufnr)
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
        generators.run(u.make_params(original_params, methods.internal.RANGE_FORMATTING), postprocess, apply_edits)

        original_params._null_ls_handled = true
    end
end

return M
