local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "perlimports",
    meta = {
        url = "https://metacpan.org/dist/App-perlimports/view/script/perlimports",
        description = "A command line utility for cleaning up imports in your Perl code",
    },
    method = DIAGNOSTICS,
    filetypes = { "perl" },
    generator_opts = {
        command = "perlimports",
        to_stdin = true,
        from_stderr = true,
        format = "line",
        args = { "--lint", "--read-stdin", "--filename", "$FILENAME" },
        timeout = 5000, -- this can take a long time
        check_exit_code = { 0, 1 },
        on_output = h.diagnostics.from_patterns({
            {
                -- pattern = [[Parse error: (.*) in (.*) on line (%d+)]],
                pattern = [[%((.*)%) at (.*) line (%d+)]],
                groups = { "message", "filename", "row" },
                overrides = {
                    diagnostic = { severity = h.diagnostics.severities["error"] },
                },
            },
        }),
    },
    factory = h.generator_factory,
})
