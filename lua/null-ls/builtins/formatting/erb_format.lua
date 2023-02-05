local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "erb-format",
    meta = {
        url = "https://github.com/nebulab/erb-formatter",
        description = "Format ERB files with speed and precision.",
    },
    method = FORMATTING,
    filetypes = { "eruby" },
    generator_opts = {
        command = "erb-format",
        args = { "--stdin" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
