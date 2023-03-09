local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "yq",
    meta = {
        url = "https://github.com/mikefarah/yq",
        description = "yq is a portable command-line YAML, JSON, XML, CSV and properties processor.",
    },
    method = FORMATTING,
    filetypes = { "yml", "yaml" },
    generator_opts = {
        command = "yq",
        args = { ".", "$FILENAME" },
        to_stdin = true,
        to_temp_file = false,
    },
    factory = h.formatter_factory,
})
