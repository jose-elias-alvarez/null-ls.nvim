local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "fish_indent",
    meta = {
        url = "https://fishshell.com/docs/current/cmds/fish_indent.html",
        description = "Indent or otherwise prettify a piece of fish code.",
    },
    method = FORMATTING,
    filetypes = { "fish" },
    generator_opts = {
        command = "fish_indent",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
