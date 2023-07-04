local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "goimports",
    meta = {
        url = "https://pkg.go.dev/golang.org/x/tools/cmd/goimports",
        description = "Updates your Go import lines, adding missing ones and removing unreferenced ones.",
    },
    method = FORMATTING,
    filetypes = { "go" },
    generator_opts = {
        command = "goimports",
        args = { "-srcdir", "$DIRNAME" },
        to_stdin = true,
        prepend_extra_args = true,
    },
    factory = h.formatter_factory,
})
