local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "golines",
    meta = {
        url = "https://pkg.go.dev/github.com/segmentio/golines",
        description = "Applies a base formatter (eg. goimports or gofmt), then shortens long lines of code.",
    },
    method = FORMATTING,
    filetypes = { "go" },
    generator_opts = {
        command = "golines",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
