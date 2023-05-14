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
        args = { "$FILENAME" },
        -- goimports-reviser doesn't support reading from stdin
        -- can use `to_stdin = true` with args = { "-output", "stdout", "$FILENAME" }
        -- when it does
        to_temp_file = true,
        prepend_extra_args = true,
    },
    factory = h.formatter_factory,
})
