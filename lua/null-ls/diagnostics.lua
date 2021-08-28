local u = require("null-ls.utils")
local s = require("null-ls.state")
local c = require("null-ls.config")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

local api = vim.api

local get_augroup_name = function(bufnr)
    return string.format("NullLsInsertLeave%s", bufnr)
end

local tracked_buffers = {}

local init_tracking = function(uri)
    local bufnr = vim.uri_to_bufnr(uri)
    api.nvim_exec(
        string.format(
            [[
        augroup %s
            autocmd!
            autocmd InsertLeave <buffer=%s> lua require("null-ls.diagnostics").run()
        augroup END
            ]],
            get_augroup_name(bufnr),
            bufnr
        ),
        false
    )

    tracked_buffers[uri] = {}
end

local clear_tracking = function(uri)
    local bufnr = vim.uri_to_bufnr(uri)
    api.nvim_exec(
        string.format(
            [[
        augroup %s
            autocmd!
        augroup END
            ]],
            get_augroup_name(bufnr)
        ),
        false
    )

    tracked_buffers[uri] = nil
end

local handle_tracked_change = function(uri, params)
    if not tracked_buffers[uri] then
        return
    end

    tracked_buffers[uri].params = params
end

local M = {}

-- assume 1-indexed ranges
local convert_range = function(diagnostic)
    local row = u.string.to_number_safe(diagnostic.row, 1)
    local col = u.string.to_number_safe(diagnostic.col, 1)
    -- default end_row to row
    local end_row = u.string.to_number_safe(diagnostic.end_row, row)
    -- default end_col to -1, which wraps to the end of the line (after range.to_lsp conversion)
    local end_col = u.string.to_number_safe(diagnostic.end_col, 0)

    return u.range.to_lsp({ row = row, col = col, end_row = end_row, end_col = end_col })
end

local postprocess = function(diagnostic, _, generator)
    diagnostic.range = convert_range(diagnostic)
    diagnostic.source = diagnostic.source or generator.opts.command or "null-ls"

    local formatted = generator and generator.opts.diagnostics_format or c.get().diagnostics_format
    -- avoid unnecessary gsub if using default
    if formatted == "#{m}" then
        return
    end

    formatted = formatted:gsub("#{m}", diagnostic.message)
    formatted = formatted:gsub("#{s}", diagnostic.source)
    formatted = formatted:gsub("#{c}", diagnostic.code or "")
    diagnostic.message = formatted
end

M.handler = function(params)
    if not params.textDocument then
        return
    end

    local method, uri = params.method, params.textDocument.uri
    if method == methods.lsp.DID_CLOSE then
        s.clear_cache(uri)
        clear_tracking(uri)
        return
    end

    if method == methods.lsp.DID_OPEN then
        init_tracking(uri)
    end

    if method == methods.lsp.DID_CHANGE then
        s.clear_cache(uri)
    end

    handle_tracked_change(uri, params)

    if api.nvim_get_mode().mode ~= "i" then
        M.run(uri)
    end
end

M.run = function(uri)
    uri = uri or vim.uri_from_bufnr(0)
    local tracked = tracked_buffers[uri]
    if not tracked or tracked.params.textDocument.version == tracked.version then
        return
    end

    local method = tracked.params.method
    local params = u.make_params(tracked.params, methods.map[method])
    generators.run_registered({
        filetype = params.ft,
        method = methods.map[method],
        params = params,
        postprocess = postprocess,
        callback = function(diagnostics)
            u.debug_log("received diagnostics from generators")
            u.debug_log(diagnostics)

            vim.lsp.handlers[methods.lsp.PUBLISH_DIAGNOSTICS](nil, nil, {
                diagnostics = diagnostics,
                uri = uri,
                ---@diagnostic disable-next-line: redundant-parameter
            }, tracked.params.client_id, nil, {})
        end,
    })

    tracked.version = tracked.params.textDocument.version
end

M._tracked_buffers = tracked_buffers

return M
