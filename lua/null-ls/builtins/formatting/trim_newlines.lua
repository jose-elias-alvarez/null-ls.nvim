local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "trim_newlines",
    method = FORMATTING,
    filetypes = {},
    generator_opts = {
        command = "awk",
        args = { 'NF{print s $0; s=""; next} {s=s ORS}' },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
