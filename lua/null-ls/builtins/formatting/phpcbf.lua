local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "phpcbf",
    meta = {
        url = "https://github.com/squizlabs/PHP_CodeSniffer",
        description = "Tokenizes PHP files and detects violations of a defined set of coding standards.",
    },
    method = FORMATTING,
    filetypes = { "php" },
    generator_opts = {
        command = "phpcbf",
        args = {
            -- silence status messages during processing
            "-q",
            -- passes the filename to phpcs, so it respects all include and exclude patterns
            "--stdin-path=$FILENAME",
            -- process stdin
            "-",
        },
        to_stdin = true,
        check_exit_code = function(code)
            -- phpcbf return a 1 or 2 exit code if it detects warnings or errors
            return code <= 2
        end,
    },
    factory = h.formatter_factory,
})
