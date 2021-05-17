local a = require("plenary.async_lib")

local u = require("null-ls.utils")
local s = require("null-ls.state")
local loop = require("null-ls.loop")
local handlers = require("null-ls.handlers")
local methods = require("null-ls.methods")
local sources = require("null-ls.sources")

local api = vim.api

local M = {}

local convert_range = function(diagnostic)
    local start_line = u.string.to_number_safe(diagnostic.row, 0, -1)
    local start_char = u.string.to_number_safe(diagnostic.col, 0)
    local end_line = u.string.to_number_safe(diagnostic.end_row, start_line, -1)
    -- default to end of line
    local end_char = u.string.to_number_safe(diagnostic.end_col, -1)

    return {
        start = {line = start_line, character = start_char},
        ["end"] = {line = end_line, character = end_char}
    }
end

local postprocess = function(diagnostic)
    diagnostic.range = convert_range(diagnostic)
    diagnostic.source = diagnostic.source or "null-ls"
end

local get_diagnostics = a.async_void(function(bufnr)
    local params = u.make_params(methods.DIAGNOSTICS, bufnr)
    local diagnostics = a.await(sources.run_generators(params, postprocess))

    handlers.diagnostics({diagnostics = diagnostics, uri = params.uri})
end)

M.attach = function(bufnr)
    if not bufnr then bufnr = api.nvim_get_current_buf() end
    if vim.fn.buflisted(bufnr) == 0 then return end

    local bufname = api.nvim_buf_get_name(bufnr)
    if s.is_attached(bufname) then return end

    local callback = vim.schedule_wrap(function() get_diagnostics(bufnr) end)
    -- immediately get buffer diagnostics
    local timer = loop.timer(0, nil, true, callback)

    api.nvim_buf_attach(bufnr, false, {
        on_lines = function() timer.restart(250) end,
        on_detach = function()
            timer.stop()
            s.detach(bufname)
        end
    })
    s.attach(bufname)
end

if _G._TEST then
    M._postprocess = postprocess
    M._get_diagnostics = get_diagnostics
end

return M
