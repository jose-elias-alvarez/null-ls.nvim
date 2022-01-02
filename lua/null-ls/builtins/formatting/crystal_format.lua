local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "crystal_format",
    method = FORMATTING,
    filetypes = { "crystal" },
    generator_opts = {
        command = "crystal",
        args = { "tool", "format" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
