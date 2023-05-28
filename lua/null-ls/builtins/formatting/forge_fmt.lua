local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "forge_fmt",
    meta = {
        url = "https://book.getfoundry.sh/reference/config/formatter",
        description = "Formats Solidity source files.",
    },
    method = FORMATTING,
    filetypes = { "solidity" },
    generator_opts = {
        command = "forge",
        args = {
            "fmt",
            "$FILENAME",
        },
        to_stdin = false,
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
