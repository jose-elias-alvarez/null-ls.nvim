local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "codespell",
    meta = {
        url = "https://github.com/codespell-project/codespell",
        description = "Codespell finds common misspellings in text files.",
    },
    method = DIAGNOSTICS,
    filetypes = {},
    generator_opts = {
        command = "codespell",
        args = { "-" },
        to_stdin = true,
        from_stderr = true,
        on_output = function(params, done)
            local output = params.output
            if not output then
                return done()
            end

            local diagnostics = {}
            local content = params.content
            local pat_diag = "(%d+): - [^\n]+\n\t((%S+)[^\n]+)"
            for row, message, misspelled in output:gmatch(pat_diag) do
                row = tonumber(row)
                -- Note: We cannot always get the misspelled columns directly from codespell (version 2.1.0) outputs,
                -- where indents in the detected lines have been truncated.
                local line = content[row]
                local col, end_col = line:find(misspelled)
                table.insert(diagnostics, {
                    row = row,
                    col = col,
                    end_col = end_col + 1,
                    source = "codespell",
                    message = message,
                    severity = 2,
                })
            end
            return done(diagnostics)
        end,
    },
    factory = h.generator_factory,
})
