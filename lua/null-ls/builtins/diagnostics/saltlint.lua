local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

return h.make_builtin({
    name = "saltlint",
    meta = {
        url = "https://github.com/warpnet/salt-lint",
        description = "A command-line utility that checks for best practices in SaltStack.",
    },
    method = methods.internal.DIAGNOSTICS_ON_SAVE,
    filetypes = { "sls" },
    generator_opts = {
        command = "salt-lint",
        to_stdin = true,
        from_stderr = true,
        args = { "--nocolor", "--json", "$FILENAME" },
        format = "json",
        on_output = h.diagnostics.from_json({
            attributes = {
                row = "linenumber",
                code = "id",
                message = "message",
                severity = "severity",
            },
            severities = {
                LOW = h.diagnostics.severities.warning,
                HIGH = h.diagnostics.severities.error,
            },
        }),
    },
    factory = h.generator_factory,
})
