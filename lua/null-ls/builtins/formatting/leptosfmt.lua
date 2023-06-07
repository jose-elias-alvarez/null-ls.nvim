local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "leptosfmt",
    meta = {
        url = "https://github.com/bram209/leptosfmt",
        description = "A formatter for the leptos view! macro",
    },
    method = FORMATTING,
    filetypes = { "rust" },
    generator_opts = {
        command = "leptosfmt",
        args = { "--quiet=true", "--stdin=true" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
