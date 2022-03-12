local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "format_r",
    meta = {
        url = "https://github.com/yihui/formatR",
        description = "Format R code automatically.",
    },
    method = FORMATTING,
    filetypes = { "r", "rmd" },
    generator_opts = {
        command = "R",
        args = h.range_formatting_args_factory({
            "--slave",
            "--no-restore",
            "--no-save",
            "-e",
            'formatR::tidy_source(source="stdin")',
        }, "--range-start", "--range-end", { row_offset = -1, col_offset = -1 }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
