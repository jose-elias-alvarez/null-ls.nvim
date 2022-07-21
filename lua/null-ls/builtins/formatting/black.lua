local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local root_resolver = require("null-ls.helpers.root_resolver")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "black",
    meta = {
        url = "https://github.com/psf/black",
        description = "The uncompromising Python code formatter",
    },
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "black",
        args = {
            "--stdin-filename",
            "$FILENAME",
            "--quiet",
            "-",
        },
        cwd = root_resolver.from_python_markers,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
