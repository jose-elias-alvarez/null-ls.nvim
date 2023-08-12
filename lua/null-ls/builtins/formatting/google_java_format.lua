local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

return h.make_builtin({
    name = "google_java_format",
    meta = {
        url = "https://github.com/google/google-java-format",
        description = "Reformats Java source code according to Google Java Style.",
    },
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = { "java" },
    generator_opts = {
        command = "google-java-format",
        args = function(params)
            if params.method == RANGE_FORMATTING and params.range then
                return {
                    "--lines",
                    params.range.row .. ":" .. params.range.end_row,
                    "--skip-sorting-imports",
                    "--skip-removing-unused-imports",
                    "--skip-javadoc-formatting",
                    "--skip-reflowing-long-strings",
                    "-",
                }
            end
            return { "-" }
        end,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
