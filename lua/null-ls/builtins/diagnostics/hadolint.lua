local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "hadolint",
    method = DIAGNOSTICS,
    filetypes = { "dockerfile" },
    generator_opts = {
        command = "hadolint",
        format = "json",
        args = { "--no-fail", "--format=json", "$FILENAME" },
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
