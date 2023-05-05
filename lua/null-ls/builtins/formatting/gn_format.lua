local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "gn_format",
    meta = {
        url = "http://gn.googlesource.com/gn",
        description = "Format your GN code!",
        notes = {
            "Install google depot_tools to use gn",
        },
    },
    method = { FORMATTING },
    filetypes = {
        "gn",
    },
    generator_opts = {
        command = "gn",
        args = {
            "format",
            "--stdin",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
