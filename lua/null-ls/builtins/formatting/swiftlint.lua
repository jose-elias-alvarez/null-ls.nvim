local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "swiftlint",
    meta = {
        url = "https://github.com/realm/SwiftLint",
        description = "A tool to enforce Swift style and conventions.",
    },
    method = FORMATTING,
    filetypes = { "swift" },
    generator_opts = {
        command = "swiftlint",
        args = { "lint", "--use-stdin", "--fix" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
