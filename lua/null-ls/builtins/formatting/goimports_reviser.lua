local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "goimports_reviser",
    meta = {
        url = "https://pkg.go.dev/github.com/incu6us/goimports-reviser",
        description = "Tool for Golang to sort goimports by 3 groups: std, general and project dependencies.",
    },
    method = FORMATTING,
    filetypes = { "go" },
    generator_opts = {
        command = "goimports-reviser",
        args = { "-file-path", "$FILENAME", "-output", "stdout" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
