local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "swiftformat",
    meta = {
        url = "https://github.com/nicklockwood/SwiftFormat",
        description = "SwiftFormat is a code library and command-line tool for reformatting `swift` code on macOS or Linux.",
    },
    method = FORMATTING,
    filetypes = { "swift" },
    generator_opts = {
        command = "swiftformat",
        args = { "--stdinpath", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
