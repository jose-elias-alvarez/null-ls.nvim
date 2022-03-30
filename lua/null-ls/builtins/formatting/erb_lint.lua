local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "erb-lint",
    meta = {
        url = "https://github.com/Shopify/erb-lint",
        description = "Lint your ERB or HTML files",
    },
    method = FORMATTING,
    filetypes = { "eruby" },
    factory = h.generator_factory,
    generator_opts = {
        command = "erblint",
        args = { "--autocorrect", "--stdin", "$FILENAME" },
        ignore_stderr = true,
        to_stdin = true,
        output = "raw",
        on_output = function(params, done)
            local output = params.output
            local metadata_end = output:match(".*==()") + 1
            return done({ { text = output:sub(metadata_end) } })
        end,
    },
})
