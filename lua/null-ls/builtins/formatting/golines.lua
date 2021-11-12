local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = { "go" },
    generator_opts = {
        command = "golines",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
