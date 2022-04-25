local methods = require("null-ls.methods")
local h = require("null-ls.helpers")
local end_col_from_quote = h.diagnostics.adapters.end_col.from_quote.end_col

local severities = {
    error = h.diagnostics.severities.error,
    errors = h.diagnostics.severities.error,
    warning = h.diagnostics.severities.warning,
    warnings = h.diagnostics.severities.warning,
}

local function parse_diagnostics(params, done)
    if not params.output then
        done(nil)
        return
    end

    local diagnostics = {}
    local current_severity = h.diagnostics.severities.error

    local output = params.output:gsub("\r\n?", "\n") or params.output
    if not output then
        done(nil)
        return
    end

    local function parse_line(line)
        local _, severity = line:match([[^(%d*) ([%w]+):$]])
        if severity then
            current_severity = severities[severity] or h.diagnostics.severities.error
            return
        end

        local filename, row, col, message = line:match([[([^:]+):(%d+):(%d+): (.*)$]])
        if not (filename and row and col and message) then
            return
        end

        -- only return diagnostics for the current file
        if filename ~= params.temp_path then
            return
        end

        local diagnostic = {
            row = row,
            col = col,
            message = message,
            severity = current_severity,
        }

        local quote = message:match([['(.+)']])
        if not quote then
            quote = message:match([[ ([^%s]+)$]])
        end
        if quote then
            local entries = {
                col = col,
                _quote = quote,
            }
            local content_line = params.content[tonumber(row)]
            diagnostic.end_col = end_col_from_quote(entries, content_line)
        end

        return diagnostic
    end

    for _, l in ipairs(vim.split(output, "\n")) do
        local diagnostic = parse_line(l)
        if diagnostic then
            table.insert(diagnostics, diagnostic)
        end
    end

    done(diagnostics)
end

return h.make_builtin({
    name = "teal",
    meta = {
        url = "https://github.com/teal-language/tl",
        description = "The compiler for Teal, a typed dialect of Lua.",
    },
    method = methods.internal.DIAGNOSTICS,
    filetypes = { "teal" },
    generator_opts = {
        command = "tl",
        args = { "check", "$FILENAME" },
        check_exit_code = function(code)
            return code <= 1
        end,
        from_stderr = true,
        to_temp_file = true,
        on_output = parse_diagnostics,
    },
    factory = h.generator_factory,
})
