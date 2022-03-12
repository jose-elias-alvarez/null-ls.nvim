local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

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
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
