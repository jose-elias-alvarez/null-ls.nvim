local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "remark",
    method = FORMATTING,
    filetypes = { "markdown" },
    generator_opts = {
        command = "remark",
        args = { "--no-color", "--silent" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
