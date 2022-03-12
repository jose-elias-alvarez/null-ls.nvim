local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "curlylint",
    meta = {
        url = "https://www.curlylint.org/",
        description = "Experimental HTML templates linting for Jinja, Nunjucks, Django templates, Twig, and Liquid.",
    },
    method = DIAGNOSTICS,
    filetypes = { "jinja.html", "htmldjango" },
    generator_opts = {
        command = "curlylint",
        name = "curlylint",
        args = {
            "--quiet",
            "-",
            "--format",
            "json",
            "--stdin-filepath",
            "$FILENAME",
        },
        to_stdin = true,
        format = "json",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_json({
            attributes = {
                row = "line",
                col = "column",
                code = "code",
                message = "message",
            },
        }),
    },
    factory = h.generator_factory,
})
