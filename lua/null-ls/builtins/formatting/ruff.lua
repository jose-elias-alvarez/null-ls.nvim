local methods = require("null-ls.methods")
local h = require("null-ls.helpers")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "ruff",
    meta = {
        url = "https://github.com/charliermarsh/ruff/",
        description = "An extremely fast Python linter, written in Rust.",
    },
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "ruff",
        args = { "--fix", "-e", "-n", "--stdin-filename", "$FILENAME", "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
