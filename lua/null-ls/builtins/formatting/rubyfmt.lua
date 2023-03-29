local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "rubyfmt",
    meta = {
        url = "https://github.com/fables-tales/rubyfmt",
        description = "Format your Ruby code!",
        notes = {
            "Install to your PATH with `brew install rubyfmt`. Ensure you have the latest version.",
        },
    },
    method = FORMATTING,
    filetypes = {
        "ruby",
    },
    generator_opts = {
        command = "rubyfmt",
        args = {},
        to_stdin = true,
        check_exit_code = { 0, 1 },
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern("Gemfile", "Gemfile.lock", "sorbet")(params.bufname)
        end),
    },
    factory = h.formatter_factory,
})
