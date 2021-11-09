local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = { "rust" },
    generator_opts = {
        command = "rustfmt",
        args = { "--emit=stdout", "--edition=2018" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
