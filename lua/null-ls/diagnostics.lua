local u = require("null-ls.utils")
local s = require("null-ls.state")
local c = require("null-ls.config")
local methods = require("null-ls.methods")
local log = require("null-ls.logger")

local api = vim.api

local should_use_diagnostic_api = function()
    return vim.diagnostic and not c.get()._use_lsp_handler
end

local namespaces = {}
local get_namespace = function(id)
    namespaces[id] = namespaces[id] or api.nvim_create_namespace("NULL_LS_SOURCE_" .. id)
    return namespaces[id]
end

local M = {}

M.namespaces = namespaces

M.hide_source_diagnostics = function(id)
    if not vim.diagnostic then
        log:debug("unable to clear diagnostics (not available on nvim < 0.6.0)")
        return
    end

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
    if should_use_diagnostic_api() then
        diagnostic.lnum = range["start"].line
        diagnostic.end_lnum = range["end"].line
        diagnostic.col = range["start"].character
        diagnostic.end_col = range["end"].character
    else
        diagnostic.range = range
    end

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

local handle_diagnostics = function(diagnostics, uri, bufnr, client_id)
    if should_use_diagnostic_api() then
        for id, by_id in pairs(diagnostics) do
            vim.diagnostic.set(get_namespace(id), bufnr, by_id)
        end
        return
    end

    local handler = u.resolve_handler(methods.lsp.PUBLISH_DIAGNOSTICS)
    handler(nil, { diagnostics = diagnostics, uri = uri }, {
        method = methods.lsp.PUBLISH_DIAGNOSTICS,
        client_id = client_id,
        bufnr = bufnr,
    })
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
        index_by_id = should_use_diagnostic_api(),
        callback = function(diagnostics)
            log:trace("received diagnostics from generators")
            log:trace(diagnostics)

            if get_last_changedtick(uri, method) > changedtick then
                log:debug("buffer changed; ignoring received diagnostics")
                return
            end

            handle_diagnostics(diagnostics, uri, bufnr, original_params.client_id)
        end,
    })
end

M.get_project_diagnostics = function()
    local method = methods.internal.PROJECT_DIAGNOSTICS
    local params = u.make_params({}, method)

    M.clear_project_diagnostics(params.ft)

    u.echo("MoreMsg", "fetching project diagnostics...")

    require("null-ls.generators").run_registered({
        filetype = params.ft,
        method = method,
        params = params,
        index_by_id = true,
        postprocess = postprocess,
        callback = function(diagnostics)
            log:debug("received project diagnostics from generators")
            log:trace(diagnostics)

            for id, by_id in pairs(diagnostics) do
                local diagnostics_by_bufnr = {}
                for _, diagnostic in ipairs(by_id) do
                    local filename = diagnostic.filename
                    local bufnr = vim.fn.bufadd(filename)
                    vim.fn.bufload(bufnr)
                    vim.fn.setbufvar(bufnr, "&buflisted", 1)

                    diagnostics_by_bufnr[bufnr] = diagnostics_by_bufnr[bufnr] or {}
                    table.insert(diagnostics_by_bufnr[bufnr], diagnostic)
                end

                for bufnr, by_bufnr in pairs(diagnostics_by_bufnr) do
                    vim.diagnostic.set(get_namespace(id), bufnr, by_bufnr)
                end

                vim.fn.setqflist(vim.diagnostic.toqflist(by_id))
            end

            u.echo("MoreMsg", "successfully fetched project diagnostics")

            if vim.tbl_count(diagnostics) > 0 then
                vim.cmd("copen | wincmd p")
            end
        end,
    })
end

M.clear_project_diagnostics = function(ft)
    local method = methods.internal.PROJECT_DIAGNOSTICS
    ft = ft or vim.bo.filetype

    local generators = require("null-ls.generators").get_available(ft, method, true)
    for id in pairs(generators) do
        M.hide_source_diagnostics(id)
    end
end

return M
