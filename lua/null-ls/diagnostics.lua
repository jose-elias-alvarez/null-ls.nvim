local u = require("null-ls.utils")
local s = require("null-ls.state")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

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

local postprocess = function(diagnostic, params)
    diagnostic.range = convert_range(diagnostic)
    diagnostic.source = diagnostic.source or params.command or "null-ls"
end

M.handler = function(original_params)
    if not original_params.textDocument then
        return
    end
    local method, uri = original_params.method, original_params.textDocument.uri
    if method == methods.lsp.DID_CHANGE then
        s.clear_cache(uri)
    end

    if method == methods.lsp.DID_CLOSE then
        return
    end

    original_params.bufnr = vim.uri_to_bufnr(uri)
    generators.run_registered(
        u.make_params(original_params, methods.internal.DIAGNOSTICS),
        postprocess,
        function(diagnostics)
            vim.lsp.handlers[methods.lsp.PUBLISH_DIAGNOSTICS](nil, nil, {
                diagnostics = diagnostics,
                uri = uri,
            }, original_params.client_id, nil, {})
        end
    )
end

return M
