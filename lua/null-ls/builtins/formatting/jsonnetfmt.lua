local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

return h.make_builtin({
    name = "jsonnetfmt",
    meta = {
        url = "https://github.com/google/jsonnet",
        description = "Formats jsonnet files.",
    },
    method = methods.internal.FORMATTING,
    filetypes = { "jsonnet" },
    generator_opts = {
        command = "jsonnetfmt",
        args = { "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
