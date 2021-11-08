local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = { "qml" },
    generator_opts = {
        command = "qmlformat",
        args = { "-i", "$FILENAME" },
        to_stdin = false,
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
