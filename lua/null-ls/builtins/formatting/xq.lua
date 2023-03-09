local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "xq",
    meta = {
        url = "https://github.com/sibprogrammer/xq",
        description = "Command-line XML and HTML beautifier and content extractor",
    },
    method = FORMATTING,
    filetypes = { "xml" },
    generator_opts = {
        command = "xq",
        args = { ".", "$FILENAME" },
        to_stdin = true,
        to_temp_file = false,
    },
    factory = h.formatter_factory,
})
