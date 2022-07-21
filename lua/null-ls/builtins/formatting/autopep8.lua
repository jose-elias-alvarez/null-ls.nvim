local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local root_resolver = require("null-ls.helpers.root_resolver")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

return h.make_builtin({
    name = "autopep8",
    meta = {
        url = "https://github.com/hhatto/autopep8",
        description = "A tool that automatically formats Python code to conform to the PEP 8 style guide.",
    },
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = { "python" },
    generator_opts = {
        command = "autopep8",
        args = h.range_formatting_args_factory({
            "-",
        }, "--line-range", nil, { use_rows = true }),
        cwd = root_resolver.from_python_markers,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
