local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "bean_format",
    meta = {
        url = "https://beancount.github.io/docs/running_beancount_and_generating_reports.html#bean-format",
        description = "This pure text processing tool will reformat `beancount` input to right-align all the numbers at the same, minimal column.",
        notes = {
            "It left-aligns all the currencies.",
            "It only modifies whitespace.",
        },
    },
    method = FORMATTING,
    filetypes = { "beancount" },
    generator_opts = {
        command = "bean-format",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
