local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    name = "rstcheck",
    meta = {
        url = "https://github.com/myint/rstcheck",
        description = "Checks syntax of reStructuredText and code blocks nested within it.",
    },
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "rst" },
    generator_opts = {
        command = "rstcheck",
        args = { "-r", "$DIRNAME" },
        to_stdin = true,
        from_stderr = true,
        format = "line",
        multiple_files = true,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_pattern(
            [[([^:]+):(%d+): %((.+)/%d%) (.+)]],
            { "filename", "row", "severity", "message" }
        ),
    },
    factory = h.generator_factory,
})
