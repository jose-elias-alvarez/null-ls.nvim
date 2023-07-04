local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "yamlfix",
    meta = {
        url = "https://github.com/lyz-code/yamlfix",
        description = "A configurable YAML formatter that keeps comments.",
    },
    method = FORMATTING,
    filetypes = { "yaml" },
    generator_opts = {
        command = "yamlfix",
        to_stdin = true,
        args = { "-" },
    },
    factory = h.formatter_factory,
})
