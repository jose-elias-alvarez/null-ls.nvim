local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "markdownlint",
    meta = {
        url = "https://github.com/DavidAnson/markdownlint",
        description = "Markdown style and syntax checker.",
    },
    method = DIAGNOSTICS,
    filetypes = { "markdown" },
    generator_opts = {
        command = "markdownlint",
        args = { "--stdin" },
        to_stdin = true,
        from_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[:(%d+):(%d+) ([%w-/]+) (.*)]],
                groups = { "row", "col", "code", "message" },
            },
            {
                pattern = [[:(%d+) ([%w-/]+) (.*)]],
                groups = { "row", "code", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})
