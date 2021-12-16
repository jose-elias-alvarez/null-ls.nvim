local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = { "my-filetype" },
    generator_opts = {
        command = "shfmt",
        args = { "-filename", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
