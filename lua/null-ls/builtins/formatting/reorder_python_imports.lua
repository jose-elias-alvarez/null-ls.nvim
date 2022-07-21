local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local root_resolver = require("null-ls.helpers.root_resolver")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "reorder_python_imports",
    meta = {
        url = "https://github.com/asottile/reorder_python_imports",
        description = "Tool for automatically reordering python imports. Similar to isort but uses static analysis more.",
    },
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "reorder-python-imports",
        args = { "-", "--exit-zero-even-if-changed" },
        cwd = root_resolver.from_python_markers,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
