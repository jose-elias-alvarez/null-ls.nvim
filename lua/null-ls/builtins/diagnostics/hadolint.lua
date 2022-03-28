local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "hadolint",
    meta = {
        url = "https://github.com/hadolint/hadolint",
        description = "A smarter Dockerfile linter that helps you build best practice Docker images.",
    },
    method = DIAGNOSTICS,
    filetypes = { "dockerfile" },
    generator_opts = {
        command = "hadolint",
        format = "json",
        to_stdin = true,
        args = { "--no-fail", "--format=json", "-" },
        on_output = h.diagnostics.from_json({
            attributes = { code = "code" },
            severities = {
                info = h.diagnostics.severities["information"],
                style = h.diagnostics.severities["hint"],
            },
        }),
    },
    factory = h.generator_factory,
})
