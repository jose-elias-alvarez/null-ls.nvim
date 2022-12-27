local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "cueimports",
    meta = {
        url = "https://pkg.go.dev/github.com/asdine/cueimports",
        description = "CUE tool that updates your import lines, adding missing ones and removing unused ones.",
    },
    method = FORMATTING,
    filetypes = { "cue" },
    generator_opts = {
        command = "cueimports",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
