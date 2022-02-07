local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "rescript",
    method = FORMATTING,
    filetypes = {
        "rescript",
    },
    generator_opts = {
        command = "rescript",
        args = { "format", "-stdin", ".res" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
