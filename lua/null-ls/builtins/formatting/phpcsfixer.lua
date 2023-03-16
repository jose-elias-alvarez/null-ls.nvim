local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "phpcsfixer",
    meta = {
        url = "https://github.com/PHP-CS-Fixer/PHP-CS-Fixer",
        description = "Formatter for php files.",
    },
    method = FORMATTING,
    filetypes = { "php" },
    generator_opts = {
        command = "php-cs-fixer",
        args = {
            "--no-interaction",
            "--quiet",
            "fix",
            "$FILENAME",
        },
        to_stdin = false,
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
