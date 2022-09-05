local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "ruff",
    meta = {
        url = "https://github.com/charliermarsh/ruff/",
        description = "An extremely fast Python linter, written in Rust.",
    },
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "ruff",
        args = {
            "-n",
            "$FILENAME",
        },
        from_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code == 0
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = "(.*):([0-9]+):([0-9]+): ([A-Z][0-9]+) (.*)",
                groups = { "file", "row", "col", "type", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})
