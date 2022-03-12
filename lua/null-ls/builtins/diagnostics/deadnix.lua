local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "deadnix",
    meta = {
        url = "https://github.com/astro/deadnix",
        description = "Scan Nix files for dead code.",
    },
    method = DIAGNOSTICS,
    filetypes = { "nix" },
    generator_opts = {
        command = "deadnix",
        args = { "--output-format=json", "$FILENAME" },
        to_temp_file = true,
        format = "json",
        on_output = function(params)
            params.output = params.output and params.output.results or {}
            local parser = h.diagnostics.from_json({
                attributes = {
                    source = "deadnix",
                },
                diagnostic = {
                    severity = h.diagnostics.severities.warning,
                },
            })
            return parser(params)
        end,
    },
    factory = h.generator_factory,
})
