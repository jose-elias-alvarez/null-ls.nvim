local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "tidy",
    meta = {
        url = "https://www.html-tidy.org/",
        description = [[Tidy corrects and cleans up HTML and XML documents by ]]
            .. [[fixing markup errors and upgrading legacy code to modern standards.]],
    },
    method = FORMATTING,
    filetypes = { "html", "xml" },
    generator_opts = {
        command = "tidy",
        args = {
            "--tidy-mark",
            "no",
            "-quiet",
            "-indent",
            "-wrap",
            "-",
        },
        to_stdin = true,
        ignore_stderr = true,
    },
    factory = h.formatter_factory,
})
