local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    name = "markdownlint-cli2",
    meta = {
        url = "https://github.com/DavidAnson/markdownlint-cli2",
        description = "A fast, flexible, configuration-based command-line interface for linting Markdown/CommonMark files with the markdownlint library",
        notes = {
            "Must be configured using a [configuration file](https://github.com/DavidAnson/markdownlint-cli2#configuration).",
            "See [the documentation](https://github.com/DavidAnson/markdownlint-cli2#overview) to understand the differences between markdownlint-cli2 and markdownlint-cli.",
        },
    },
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "markdown" },
    generator_opts = {
        command = "markdownlint-cli2",
        from_stderr = true,
        format = "line",
        multiple_files = true,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[(%g+):(%d+):(%d+) ([%w-/]+) (.*)]],
                groups = { "filename", "row", "col", "code", "message" },
                overrides = { diagnostic = { severity = 2 } },
            },
            {
                pattern = [[(%g+):(%d+) ([%w-/]+) (.*)]],
                groups = { "filename", "row", "code", "message" },
                overrides = { diagnostic = { severity = 2 } },
            },
        }),
    },
    factory = h.generator_factory,
})
