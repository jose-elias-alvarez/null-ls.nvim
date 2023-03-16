local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "crystal_format",
    meta = {
        url = "https://github.com/crystal-lang/crystal",
        description = "A tool for automatically checking and correcting the style of code in a project.",
    },
    method = FORMATTING,
    filetypes = { "crystal" },
    generator_opts = {
        command = "crystal",
        args = { "tool", "format", "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
