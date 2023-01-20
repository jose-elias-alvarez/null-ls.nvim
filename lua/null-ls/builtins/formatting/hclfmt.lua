local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "hclfmt",
    meta = {
        url = "https://github.com/fatih/hclfmt",
        description = "Formatter for HCL configuration files",
    },
    method = FORMATTING,
    filetypes = { "hcl" },
    generator_opts = {
        command = "hclfmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
