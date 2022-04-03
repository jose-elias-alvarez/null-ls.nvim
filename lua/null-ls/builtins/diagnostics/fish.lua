local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

return h.make_builtin({
    name = "fish",
    meta = {
        url = "https://github.com/fish-shell/fish-shell",
        description = "Basic linting is available for fish scripts using `fish --no-execute`.",
    },
    method = methods.internal.DIAGNOSTICS,
    filetypes = { "fish" },
    factory = h.generator_factory,
    generator_opts = {
        command = "fish",
        args = { "--no-execute", "$FILENAME" },
        to_stdin = false,
        from_stderr = true,
        to_temp_file = true,
        format = "raw",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_errorformat(table.concat({ "%f (line %l): %m" }, ","), "fish"),
    },
})
