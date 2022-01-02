local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "buildifier",
    method = FORMATTING,
    filetypes = { "bzl" },
    generator_opts = {
        command = "buildifier",
        -- This is needed for buildifier to be able to deduce the relative workspace path.
        -- Without this, sorting sources and deps doesn't appear to work.
        args = { "-path=$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
