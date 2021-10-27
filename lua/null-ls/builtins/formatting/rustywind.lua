local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
        "html",
    },
    generator_opts = {
        command = "rustywind",
        args = { "--stdin" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
