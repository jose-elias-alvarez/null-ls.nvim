local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "mdformat",
    meta = {
        url = "https://github.com/executablebooks/mdformat",
        description = "An opinionated Markdown formatter that can be used to enforce a consistent style in Markdown files",
        notes = {
            "Mdformat offers an extensible plugin system for both code fence content formatting and Markdown parser extensions (like GFM tables). A comprehensive list of plugins is documented [here](https://mdformat.readthedocs.io/en/stable/users/plugins.html) ",
        },
    },
    method = FORMATTING,
    filetypes = { "markdown" },
    generator_opts = {
        command = "mdformat",
        args = { "$FILENAME" },
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
