local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "mix",
    meta = {
        url = "https://hexdocs.pm/mix/1.12/Mix.html",
        description = "Build tool that provides tasks for creating, compiling, and testing elixir projects, managing its dependencies, and more.",
    },
    method = FORMATTING,
    filetypes = { "elixir" },
    generator_opts = {
        command = "mix",
        args = { "format", "--stdin-filename", "$FILENAME", "-" },
        format = "raw",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
