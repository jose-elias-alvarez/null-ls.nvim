local a = require("plenary.async_lib")

local s = require("null-ls.state")
local c = require("null-ls.config")
local u = require("null-ls.utils")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

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

    local current_winid = api.nvim_get_current_win()
    local positions = {}
    for _, w in ipairs(vim.fn.getwininfo()) do
        if w.bufnr == bufnr and w.winid ~= current_winid then
            positions[w.winid] = api.nvim_win_get_cursor(w.winid)
        end
    end

    return marks, positions
end

local restore_win_data = function(marks, positions, bufnr)
    -- no need to restore marks that still exist
    for _, m in pairs(vim.fn.getmarklist(bufnr)) do
        marks[m.mark] = nil
    end
    for mark, pos in pairs(marks) do
        if pos then
            vim.fn.setpos(mark, pos)
        end
    end

    local line_count = api.nvim_buf_line_count(bufnr)
    for winid, pos in pairs(positions) do
        if pos[1] > line_count then
            api.nvim_win_set_cursor(winid, { line_count, 0 })
        else
            api.nvim_win_set_cursor(winid, pos)
        end
    end
end

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
    u.debug_log("received edits from generators")
    u.debug_log(edits)

    local bufnr = params.bufnr
    local marks, positions = save_win_data(bufnr)

    -- default handler doesn't accept bufnr, so call util directly
    lsp.util.apply_text_edits(edits, bufnr)
    restore_win_data(marks, positions, bufnr)

    if c.get().save_after_format and not _G._TEST then
        local current_bufnr = api.nvim_win_get_buf(0)
        vim.cmd(bufnr .. "bufdo! silent keepjumps noautocmd update")

        if current_bufnr ~= bufnr then
            api.nvim_win_set_buf(0, current_bufnr)
        end
    end

    -- call original handler with empty response so buf.request_sync() doesn't time out
    handler(nil, methods.lsp.FORMATTING, {}, s.get().client_id, bufnr)
    u.debug_log("successfully applied edits")
end)

M.handler = function(method, original_params, handler, bufnr)
    if method == methods.lsp.FORMATTING then
        u.debug_log("received LSP formatting request")

        original_params.bufnr = bufnr
        apply_edits(original_params, handler)

        original_params._null_ls_handled = true
    end
end

return M
