local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "gersemi",
    meta = {
        url = "https://github.com/BlankSpruce/gersemi",
        description = "A formatter to make your CMake code the real treasure",
    },
    method = FORMATTING,
    filetypes = { "cmake" },
    generator_opts = {
        command = "gersemi",
        args = { "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
