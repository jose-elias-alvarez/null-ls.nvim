local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "ocamlformat",
    meta = {
        url = "https://github.com/ocaml-ppx/ocamlformat",
        description = "Auto-formatter for OCaml code",
    },
    method = FORMATTING,
    filetypes = { "ocaml" },
    generator_opts = {
        command = "ocamlformat",
        args = { "--enable-outside-detected-project", "--name", "$FILENAME", "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
