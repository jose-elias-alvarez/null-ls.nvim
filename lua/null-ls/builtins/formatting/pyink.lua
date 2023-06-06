local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

return h.make_builtin({
    name = "pyink",
    meta = {
        url = "https://github.com/google/pyink",
        description = "The Google Python code formatter",
    },
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = { "python" },
    generator_opts = {
        command = "pyink",
        args = h.range_formatting_args_factory({
            "--stdin-filename",
            "$FILENAME",
            "--quiet",
            "-",
        }, "--pyink-lines", nil, { use_rows = true, delimiter = "-" }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
