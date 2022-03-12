local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "zigfmt",
    meta = {
        url = "https://github.com/ziglang/zig",
        description = "Reformat Zig source into canonical form.",
    },
    method = FORMATTING,
    filetypes = { "zig" },
    generator_opts = {
        command = "zig",
        args = { "fmt", "--stdin" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
