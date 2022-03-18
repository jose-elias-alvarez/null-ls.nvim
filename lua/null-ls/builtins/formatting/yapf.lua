local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local root_resolver = require("null-ls.helpers.root_resolver")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

return h.make_builtin({
    name = "yapf",
    meta = {
        url = "https://github.com/google/yapf",
        description = "Formatter for Python.",
    },
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = { "python" },
    generator_opts = {
        command = "yapf",
        args = h.range_formatting_args_factory({
            "--quiet",
        }, "--lines", nil, { use_rows = true, delimiter = "-" }),
        cwd = root_resolver.from_python_markers,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
