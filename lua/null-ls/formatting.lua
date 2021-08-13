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

    local views = {}
    for _, win in pairs(vim.api.nvim_list_wins() or {}) do
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
        if api.nvim_win_is_valid(win) then
            api.nvim_win_call(win, function()
                vim.fn.winrestview(view)
            end)
        end
    end
end

---@param edits table[]
---@param params table
M.apply_edits = function(edits, params)
    local bufnr = params.bufnr
    -- directly use lsp handler, since formatting_sync uses a custom handler that won't work if called twice
    -- formatting and rangeFormatting handlers are identical
    local handler = lsp.handlers[params.lsp_method]

    u.debug_log("received edits from generators")
    u.debug_log(edits)

    local diffed_edits = {}
    for _, edit in ipairs(edits) do
        local diffed = lsp.util.compute_diff(params.content, vim.split(edit.text, "\n"))
        -- check if the computed diff is an actual edit
        if
            not (
                diffed.text == ""
                and diffed.range.start.character == diffed.range["end"].character
                and diffed.range.start.line == diffed.range["end"].line
            )
        then
            table.insert(diffed_edits, { newText = diffed.text, range = diffed.range })
        end
    end

    local marks, views = save_win_data(bufnr)

    ---@diagnostic disable-next-line: redundant-parameter
    handler(nil, params.lsp_method, diffed_edits, params.client_id, bufnr)

    vim.schedule(function()
        restore_win_data(marks, views, bufnr)
    end)

    u.debug_log("successfully applied edits")
end

M.handler = function(method, original_params, handler)
    if not original_params.textDocument then
        return
    end

    if method == methods.lsp.FORMATTING or method == methods.lsp.RANGE_FORMATTING then
        local bufnr = vim.uri_to_bufnr(original_params.textDocument.uri)
        generators.run_registered_sequentially({
            filetype = api.nvim_buf_get_option(bufnr, "filetype"),
            method = methods.map[method],
            make_params = function()
                return u.make_params(original_params, methods.map[method])
            end,
            callback = function(edits, params)
                M.apply_edits(edits, params)
            end,
            after_all = function()
                -- call original handler with empty response to avoid formatting_sync timeout
                handler(nil, method, nil, original_params.client_id, bufnr)
            end,
        })

        original_params._null_ls_handled = true
    end
end

return M
