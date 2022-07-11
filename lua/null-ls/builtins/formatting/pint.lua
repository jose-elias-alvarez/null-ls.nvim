local h = require("null-ls.helpers")
local u = require("null-ls.utils")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "pint",
    meta = {
        url = "https://github.com/laravel/pint",
        description = "An opinionated PHP code style fixer for minimalists.",
    },
    method = FORMATTING,
    filetypes = { "php" },
    generator_opts = {
        command = "./vendor/bin/pint",
        args = {
            "--no-interaction",
            "--quiet",
            "$FILENAME",
        },
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern("pint.json", "composer.json", "composer.lock")(params.bufname)
        end),
        to_stdin = false,
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
