local h = require("null-ls.helpers")
local DIAGNOSTICS = require("null-ls.methods").internal.DIAGNOSTICS

return h.make_builtin({
    name = "solhint",
    meta = {
        url = "https://protofire.github.io/solhint/",
        description = "An open source project for linting Solidity code. It provides both security and style guide validations.",
    },
    method = DIAGNOSTICS,
    filetypes = { "solidity" },
    factory = h.generator_factory,
    generator_opts = {
        args = {
            "$FILENAME",
            "--formatter",
            "unix",
        },
        command = "solhint",
        format = "line",
        from_stderr = false,
        on_output = h.diagnostics.from_pattern("([^:]*):([%d]+):([%d]+): (.*) %[([%a]+)/([%a%p]+)%]", {
            "filename",
            "row",
            "col",
            "message",
            "severity",
            "code",
        }, {
            severities = {
                ["Error"] = h.diagnostics.severities.error,
                ["Warning"] = h.diagnostics.severities.warning,
            },
        }),
        to_stdin = true,
    },
})
