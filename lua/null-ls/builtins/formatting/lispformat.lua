local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "lispformat",
    meta = {
        url = "https://github.com/eschulte/lisp-format",
        description = "A tool to format lisp code. Designed to mimic clang-format.",
        notes = {
            "This requires a working installation of vanilla Emacs. To install Emacs, refer to the [installation instructions](https://www.gnu.org/software/emacs/manual/html_node/efaq/Installing-Emacs.html) or use a package manager.",
        },
    },
    method = FORMATTING,
    filetypes = { "lisp" },
    generator_opts = {
        command = "lisp-format",
        args = { "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
