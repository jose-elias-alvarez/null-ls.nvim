local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "bibclean",
    meta = {
        url = "https://www.ctan.org/pkg/bibclean",
        description = "A portable program (written in C) that will pretty-print, syntax check, and generally sort out a BibTeX database file.",
        notes = {
            "See [bibclean: prettyprint and syntax check BibTeX and Scribe bibliography data base files](https://ftp.math.utah.edu/pub/bibclean/) for latest version.",
        },
    },
    method = FORMATTING,
    filetypes = { "bib" },
    generator_opts = {
        command = "bibclean",
        args = { "-align-equals", "-delete-empty-values" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
