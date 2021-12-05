local u = require("null-ls.utils")
local s = require("null-ls.state")
local c = require("null-ls.config")
local methods = require("null-ls.methods")
local log = require("null-ls.logger")

local api = vim.api

local namespaces = {}

local M = {}

M.namespaces = namespaces

M.hide_source_diagnostics = function(id)
    local ns = namespaces[id]
    if not ns then
        return
    end

    vim.diagnostic.reset(ns)
end

-- assume 1-indexed ranges
local convert_range = function(diagnostic)
    local row = tonumber(diagnostic.row or 1)
    local col = tonumber(diagnostic.col or 1)
    local end_row = tonumber(diagnostic.end_row or row)
    local end_col = tonumber(diagnostic.end_col or 1)
    -- wrap to next line
    if end_row == row and end_col <= col then
        end_row = end_row + 1
        end_col = 1
    end

    return u.range.to_lsp({ row = row, col = col, end_row = end_row, end_col = end_col })
end

local postprocess = function(diagnostic, _, generator)
    local range = convert_range(diagnostic)
    -- the diagnostic API requires 0-indexing, so we can repurpose the LSP range
    diagnostic.lnum = range["start"].line
    diagnostic.end_lnum = range["end"].line
    diagnostic.col = range["start"].character
    diagnostic.end_col = range["end"].character

    diagnostic.source = diagnostic.source or generator.opts.name or generator.opts.command or "null-ls"

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

local handle_diagnostics = function(diagnostics, bufnr)
    for id, by_id in pairs(diagnostics) do
        namespaces[id] = namespaces[id] or api.nvim_create_namespace("NULL_LS_SOURCE_" .. id)
        vim.diagnostic.set(namespaces[id], bufnr, by_id)
    end
end

-- track last changedtick to only send most recent diagnostics
local changedticks_by_uri = {}

local set_last_changedtick = function(changedtick, uri, method)
    changedticks_by_uri[uri] = changedticks_by_uri[uri] or {}
    changedticks_by_uri[uri][method] = changedticks_by_uri[uri][method] or {}
    changedticks_by_uri[uri][method] = changedtick
end

local get_last_changedtick = function(uri, method)
    return changedticks_by_uri[uri] and changedticks_by_uri[uri][method] or -1
end

M.handler = function(original_params)
    if not original_params.textDocument then
        return
    end

    local method, uri = original_params.method, original_params.textDocument.uri
    local bufnr = vim.uri_to_bufnr(uri)

    if method == methods.lsp.DID_CLOSE then
        changedticks_by_uri[uri] = nil
        s.clear_cache(uri)
        s.clear_commands(bufnr)
        return
    end

    if method == methods.lsp.DID_CHANGE then
        s.clear_cache(uri)
    end

    local changedtick = original_params.textDocument.version or api.nvim_buf_get_changedtick(bufnr)

    if method == methods.lsp.DID_SAVE and changedtick == get_last_changedtick(uri, method) then
        log:debug("buffer unchanged; ignoring didSave notification")
        return
    end

    local params = u.make_params(original_params, methods.map[method])
    set_last_changedtick(changedtick, uri, method)

    require("null-ls.generators").run_registered({
        filetype = params.ft,
        method = methods.map[method],
        params = params,
        postprocess = postprocess,
        index_by_id = true,
        callback = function(diagnostics)
            log:trace("received diagnostics from generators")
            log:trace(diagnostics)

            if get_last_changedtick(uri, method) > changedtick then
                log:debug("buffer changed; ignoring received diagnostics")
                return
            end

            handle_diagnostics(diagnostics, bufnr)
        end,
    })
end

return M
