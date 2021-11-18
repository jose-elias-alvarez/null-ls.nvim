local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "php" },
    generator_opts = {
        command = "php",
        to_stdin = false,
        to_temp_file = true,
        args = { "-l", "$FILENAME" },
        format = "line",
        check_exit_code = function()
            return true
        end,
        on_output = h.diagnostics.from_patterns({
            {
                -- Parse error: syntax error, unexpected '$appends' (T_VARIABLE), expecting function (T_FUNCTION) or const (T_CONST) in app/Config.php on line 16
                pattern = [[Parse error: (.*) (%d+)]],
                groups = { "message", "row" },
                overrides = {
                    diagnostic = { severity = h.diagnostics.severities["error"] },
                    offsets = { col = 1, end_col = 1 },
                },
            },
        }),
    },
    factory = h.generator_factory,
})
