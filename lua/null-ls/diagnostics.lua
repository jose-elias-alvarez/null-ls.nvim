local u = require("null-ls.utils")
local s = require("null-ls.state")
local c = require("null-ls.config")
local methods = require("null-ls.methods")
local log = require("null-ls.logger")

local api = vim.api

local namespaces = {}
local get_namespace = function(id)
    if namespaces[id] then
        return namespaces[id]
    end

    local namespace = api.nvim_create_namespace("NULL_LS_SOURCE_" .. id)

    local source = require("null-ls.sources").get({ id = id })[1]
    local diagnostic_config = source and source.generator.opts and source.generator.opts.diagnostic_config
        or c.get().diagnostic_config
    if diagnostic_config then
        vim.diagnostic.config(diagnostic_config, namespace)
    end

    namespaces[id] = namespace
    return namespace
end

local M = {}

M.get_namespace = get_namespace

M._reset_namespaces = function()
    namespaces = {}
end

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
    diagnostic.lnum = range["start"].line
    diagnostic.end_lnum = range["end"].line
    diagnostic.col = range["start"].character
    diagnostic.end_col = range["end"].character
    diagnostic.severity = diagnostic.severity or c.get().fallback_severity

    diagnostic.source = diagnostic.source or generator.opts.name or generator.opts.command or "null-ls"
    if diagnostic.filename and not diagnostic.bufnr then
        local bufnr = vim.fn.bufadd(diagnostic.filename)
        diagnostic.bufnr = bufnr
    end

    local user_postprocess = generator.opts.diagnostics_postprocess
    if user_postprocess then
        user_postprocess(diagnostic)
        return
    end

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

local handle_single_file_diagnostics = function(namespace, diagnostics, bufnr)
    vim.diagnostic.set(namespace, bufnr, diagnostics)
end

local handle_multiple_file_diagnostics = function(namespace, diagnostics)
    local by_bufnr = {}
    for _, diagnostic in ipairs(diagnostics) do
        if not diagnostic.bufnr then
            log:debug(string.format("received multiple-file diagnostic without bufnr: %s", vim.inspect(diagnostic)))
        else
            by_bufnr[diagnostic.bufnr] = by_bufnr[diagnostic.bufnr] or {}
            table.insert(by_bufnr[diagnostic.bufnr], diagnostic)
        end
    end

    -- clear stale diagnostics
    for _, old_diagnostic in ipairs(vim.diagnostic.get(nil, { namespace = namespace })) do
        by_bufnr[old_diagnostic.bufnr] = by_bufnr[old_diagnostic.bufnr] or {}
    end

    for bufnr, bufnr_diagnostics in pairs(by_bufnr) do
        vim.diagnostic.set(namespace, bufnr, bufnr_diagnostics)
    end
end

local handle_diagnostics = function(id, diagnostics, bufnr, multiple_files)
    for _, diagnostic in ipairs(diagnostics) do
        local bnr = bufnr
        if multiple_files then
            bnr = diagnostic.bufnr
        end
        local start_line = vim.api.nvim_buf_get_lines(bnr, diagnostic.lnum, diagnostic.lnum + 1, false)[1]
        diagnostic.col = vim.str_byteindex(start_line, diagnostic.col)
        -- automatic search for valid end coordinates for sources that don't provide them
        diagnostic.end_col, diagnostic.end_lnum = (setmetatable({
            end_col = diagnostic.end_col,
            end_lnum = diagnostic.end_lnum,
        }, {
            __call = function(self)
                local end_line = vim.api.nvim_buf_get_lines(bnr, self.end_lnum, self.end_lnum + 1, false)[1]
                local ok, end_col = pcall(vim.str_byteindex, end_line, self.end_col)
                if not ok then
                    self.end_lnum = self.end_lnum + 1
                    self.end_col = self.end_col - vim.api.nvim_strwidth(end_line) - 1
                    return self()
                end
                return end_col, self.end_lnum
            end,
        }))()
    end
    local namespace = get_namespace(id)
    if multiple_files then
        handle_multiple_file_diagnostics(namespace, diagnostics)
    else
        handle_single_file_diagnostics(namespace, diagnostics, bufnr)
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

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    if method == methods.lsp.DID_CLOSE then
        changedticks_by_uri[uri] = nil
        s.clear_cache(uri)
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
        after_each = function(diagnostics, _, generator)
            if not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end
            local source_id, multiple_files = generator.source_id, generator.multiple_files
            log:trace("received diagnostics from source " .. source_id)
            log:trace(vim.inspect(diagnostics))

            if get_last_changedtick(uri, method) > changedtick then
                log:debug("buffer changed; ignoring received diagnostics")
                return
            end

            handle_diagnostics(source_id, diagnostics, bufnr, multiple_files)
        end,
    })
end

return M
