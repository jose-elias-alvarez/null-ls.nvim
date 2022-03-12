local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "gitlint",
    meta = {
        url = "https://jorisroovers.com/gitlint/",
        description = "Linter for Git commit messages.",
    },
    method = DIAGNOSTICS,
    filetypes = { "gitcommit" },
    generator_opts = {
        command = "gitlint",
        args = { "--msg-filename", "$FILENAME" },
        to_temp_file = true,
        from_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[(%d+): (%w+) (.+)]],
                groups = { "row", "code", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})
