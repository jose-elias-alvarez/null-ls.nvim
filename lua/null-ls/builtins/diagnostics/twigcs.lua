local null_ls = require("null-ls")
local h = require("null-ls.helpers")

return h.make_builtin({
    name = "twigcs",
    meta = {
        url = "https://github.com/friendsoftwig/twigcs",
        description = "Runs Twigcs against Twig files.",
    },
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = { "twig" },
    generator_opts = {
        command = "twigcs",
        args = { "--reporter", "json", "$FILENAME" },
        format = "json",
        to_temp_file = true,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(params)
            local parser = h.diagnostics.from_json({
                attributes = {
                    row = "line",
                    col = "column",
                    severity = "severity",
                },
                severities = {
                    h.diagnostics.severities["information"],
                    h.diagnostics.severities["warning"],
                    h.diagnostics.severities["error"],
                    h.diagnostics.severities["hint"],
                },
            })
            params.violations = params.output
                    and params.output.files
                    and params.output.files[1]
                    and params.output.files[1].violations
                or {}

            return parser({ output = params.violations })
        end,
    },

    factory = h.generator_factory,
})
