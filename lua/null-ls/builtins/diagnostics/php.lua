-- Tested using PHP 7.x and PHP 8.x.
local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "php",
    meta = {
        url = "https://www.php.net/",
        description = "Uses the php command-line tool's built in `-l` flag to check for syntax errors.",
    },
    method = DIAGNOSTICS,
    filetypes = { "php" },
    generator_opts = {
        command = "php",
        -- Send file to stdin otherwise checking is only done when the file is saved.
        to_stdin = true,
        to_temp_file = false,
        -- -d display_errors=STDERR ensures errors are reported to stderr.
        -- -d log_errors=Off Disables logging of errors.
        --
        -- Without these, a setting in php.ini can turn off error reporting, or
        -- change where errors are reported.
        args = { "-l", "-d", "display_errors=STDERR", "-d", " log_errors=Off" },
        from_stderr = true,
        format = "line",
        check_exit_code = function(code)
            -- Code 0 means no syntax errors.
            -- Code 255 means syntax errors.
            -- Other codes mean something went wrong.
            return code == 0 or code == 255
        end,
        on_output = h.diagnostics.from_patterns({
            {
                -- Example of an error when checking a file:
                -- Parse error: syntax error, unexpected '$appends' (T_VARIABLE), expecting function (T_FUNCTION) or const (T_CONST) in app/Config.php on line 16

                -- Example of an error when checking stdin:
                -- Parse error: syntax error, unexpected token "=>", expecting "," or ";" in Standard input code on line 21

                -- This pattern should match both.
                pattern = [[Parse error: (.*) in (.*) on line (%d+)]],
                groups = { "message", "junk", "row" },
                overrides = {
                    diagnostic = { severity = h.diagnostics.severities["error"] },
                    offsets = { col = 1, end_col = 1 },
                },
            },
        }),
    },
    factory = h.generator_factory,
})
