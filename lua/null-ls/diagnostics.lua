local u = require("null-ls.utils")
local s = require("null-ls.state")
local c = require("null-ls.config")
local methods = require("null-ls.methods")

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

M.handler = function(original_params)
    if not original_params.textDocument then
        return
    end
    local method, uri = original_params.method, original_params.textDocument.uri
    if method == methods.lsp.DID_CLOSE then
        s.clear_cache(uri)
        return
    end

    if method == methods.lsp.DID_CHANGE then
        s.clear_cache(uri)
    end

    local params = u.make_params(original_params, methods.map[method])
    require("null-ls.generators").run_registered({
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
            }, original_params.client_id, nil, {})
        end,
    })
end

return M
