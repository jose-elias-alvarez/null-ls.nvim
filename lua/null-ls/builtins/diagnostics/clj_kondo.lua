local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local on_output = h.diagnostics.from_pattern([[:(%d+):(%d+): (%w+): (.*)]], { "row", "col", "severity", "message" })

return h.make_builtin({
    name = "clj-kondo",
    meta = {
        url = "https://github.com/clj-kondo/clj-kondo",
        description = "A linter for clojure code that sparks joy",
    },
    method = DIAGNOSTICS,
    filetypes = { "clojure" },
    generator_opts = {
        command = "clj-kondo",
        args = { "--cache", "--lint", "-", "--filename", "$FILENAME" },
        to_stdin = true,
        format = "line",
        -- 0 -> No errors or warnings
        -- 2 -> One or more warnings
        -- 3 -> One or more errors
        check_exit_code = { 0, 2, 3 },
        on_output = function(line, params)
            if not string.match(line, "^linting took ") then
                return on_output(line, params)
            end
        end,
        severities = {
            error = h.diagnostics.severities["error"],
            Exception = h.diagnostics.severities["error"],
            warning = h.diagnostics.severities["warning"],
        },
    },
    factory = h.generator_factory,
})
