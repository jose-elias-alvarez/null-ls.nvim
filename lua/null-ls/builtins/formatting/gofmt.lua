local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "gofmt",
    meta = {
        url = "https://pkg.go.dev/cmd/gofmt",
        description = "Formats go programs.",
        notes = {
            "It uses tabs for indentation and blanks for alignment.",
            "Aligntment assumes that the editor is using a fixed-width font.",
        },
    },
    method = FORMATTING,
    filetypes = { "go" },
    generator_opts = {
        command = "gofmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
