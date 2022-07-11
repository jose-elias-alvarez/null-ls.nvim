local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "csharpier",
    meta = {
        url = "https://csharpier.com/",
        description = "CSharpier is an opinionated code formatter for c#",
    },
    method = FORMATTING,
    filetypes = { "cs" },
    generator_opts = {
        command = "dotnet-csharpier",
        args = {
            "--write-stdout",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
