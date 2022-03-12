local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "clang_format",
    meta = {
        url = "https://www.kernel.org/doc/html/latest/process/clang-format.html",
        description = "Tool to format C/C++/… code according to a set of rules and heuristics.",
    },
    method = FORMATTING,
    filetypes = { "c", "cpp", "cs", "java" },
    generator_opts = {
        command = "clang-format",
        args = { "-assume-filename", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
