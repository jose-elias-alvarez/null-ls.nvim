local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = { "r", "rmd" },
    generator_opts = {
        command = "R",
        args = h.range_formatting_args_factory({
            "--slave",
            "--no-restore",
            "--no-save",
            "-e",
            'con=file("stdin");output=styler::style_text(readLines(con));close(con);print(output, colored=FALSE)',
        }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
