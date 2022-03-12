local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "cmake_format",
    meta = {
        url = "https://github.com/cheshirekow/cmake_format",
        description = "Parse cmake listfiles and format them nicely.",
    },
    method = FORMATTING,
    filetypes = { "cmake" },
    generator_opts = {
        command = "cmake-format",
        args = { "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
