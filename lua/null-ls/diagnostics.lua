local u = require("null-ls.utils")
local s = require("null-ls.state")
local c = require("null-ls.config")
local methods = require("null-ls.methods")

local M = {}

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
    diagnostic.range = convert_range(diagnostic)
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
    local handler = u.resolve_handler(methods.lsp.PUBLISH_DIAGNOSTICS)
    require("null-ls.generators").run_registered({
        filetype = params.ft,
        method = methods.map[method],
        params = params,
        postprocess = postprocess,
        callback = function(diagnostics)
            u.debug_log("received diagnostics from generators")
            u.debug_log(diagnostics)

            local bufnr = vim.uri_to_bufnr(uri)
            if vim.fn.has("nvim-0.5.1") > 0 then
                handler(nil, { diagnostics = diagnostics, uri = uri }, {
                    method = methods.lsp.PUBLISH_DIAGNOSTICS,
                    client_id = original_params.client_id,
                    bufnr = bufnr,
                })
            else
                handler(nil, methods.lsp.PUBLISH_DIAGNOSTICS, {
                    diagnostics = diagnostics,
                    uri = uri,
                    ---@diagnostic disable-next-line: redundant-parameter
                }, original_params.client_id, bufnr)
            end
        end,
    })
end

return M
