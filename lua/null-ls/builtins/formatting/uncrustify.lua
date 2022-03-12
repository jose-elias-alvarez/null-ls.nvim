local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "uncrustify",
    meta = {
        url = "https://github.com/uncrustify/uncrustify",
        description = "A source code beautifier for C, C++, C#, ObjectiveC, D, Java, Pawn and Vala.",
    },
    method = FORMATTING,
    filetypes = { "c", "cpp", "cs", "java" },
    generator_opts = {
        command = "uncrustify",
        args = function(params)
            local format_type = "-l " .. params.ft:upper()
            return { "-q", format_type }
        end,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
