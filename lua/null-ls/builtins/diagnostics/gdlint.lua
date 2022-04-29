local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "gdlint",
    meta = {
        url = "https://github.com/Scony/godot-gdscript-toolkit",
        description = "A linter that performs a static analysis on gdscript code according to some predefined configuration.",
    },
    method = DIAGNOSTICS,
    filetypes = { "gdscript" },
    generator_opts = {
        command = "gdlint",
        args = { "$FILENAME" },
        to_stdin = false,
        from_stderr = true,
        to_temp_file = true,
        format = "line",
        check_exit_code = function(code)
            return code > 0
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[:(%d+): (.*)]],
                groups = { "row", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})
