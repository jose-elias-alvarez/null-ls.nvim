local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "prettier_standard",
    method = FORMATTING,
    filetypes = { "javascript", "javascriptreact" },
    generator_opts = {
        command = "prettier-standard",
        args = { "--stdin" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
