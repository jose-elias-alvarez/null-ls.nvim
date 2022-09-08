local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "phpcs",
    meta = {
        url = "https://github.com/squizlabs/PHP_CodeSniffer",
        description = "PHP_CodeSniffer is a script that tokenizes PHP, JavaScript and CSS files to detect violations of a defined coding standard.",
    },
    method = DIAGNOSTICS,
    filetypes = { "php" },
    generator_opts = {
        command = "phpcs",
        args = {
            "--report=json",
            -- silence status messages during processing as they are invalid JSON
            "-q",
            -- always report codes
            "-s",
            -- phpcs exits with a non-0 exit code when messages are reported but we only want to know if the command fails
            "--runtime-set",
            "ignore_warnings_on_exit",
            "1",
            "--runtime-set",
            "ignore_errors_on_exit",
            "1",
            -- process stdin
            "--stdin-path=$FILENAME",
            -- get absolute paths under params.output.files
            "--basepath=",
        },
        format = "json_raw",
        to_stdin = true,
        from_stderr = false,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(params)
            local parser = h.diagnostics.from_json({
                attributes = {
                    severity = "type",
                    code = "source",
                },
                severities = {
                    ERROR = h.diagnostics.severities["error"],
                    WARNING = h.diagnostics.severities["warning"],
                },
            })
            params.messages = params.output
                    and params.output.files
                    and params.output.files[params.bufname]
                    and params.output.files[params.bufname].messages
                or {}

            return parser({ output = params.messages })
        end,
    },
    factory = h.generator_factory,
})
