local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "remark",
    meta = {
        url = "https://github.com/remarkjs/remark",
        description = "remark is an extensive and complex Markdown formatter/prettifier.",
        notes = {
            "Depends on [remark-cli](https://github.com/remarkjs/remark/tree/main/packages/remark-cli).",
        },
    },
    method = FORMATTING,
    filetypes = { "markdown" },
    generator_opts = {
        command = "remark",
        args = { "--no-color", "--silent" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
