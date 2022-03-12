local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "deno_fmt",
    meta = {
        url = "https://deno.land/manual/tools/formatter",
        description = "Use [Deno](https://deno.land/) to format TypeScript and JavaScript code.",
    },
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
    },
    generator_opts = {
        command = "deno",
        args = { "fmt", "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
