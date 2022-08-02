local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "ocdc",
    meta = {
        url = "https://github.com/mdwint/ocdc",
        description = "A changelog formatter",
    },
    method = FORMATTING,
    filetypes = { "markdown" },
    generator_opts = {
        command = "ocdc",
        args = { "--path", "-" },
        to_stdin = true,
        runtime_condition = function(params)
            return params.bufname:lower():match("[/\\]changelog.md$")
        end,
    },
    factory = h.formatter_factory,
})
