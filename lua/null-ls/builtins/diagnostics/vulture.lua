local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local root_resolver = require("null-ls.helpers.root_resolver")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "vulture",
    meta = {
        url = "https://github.com/jendrikseipp/vulture",
        description = "Vulture finds unused code in Python programs.",
    },
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "vulture",
        args = { "$FILENAME" },
        cwd = root_resolver.from_python_markers,
        to_temp_file = true,
        from_stderr = true,
        format = "line",
        on_output = h.diagnostics.from_pattern([[:(%d+): (.*)]], { "row", "message" }),
    },
    factory = h.generator_factory,
})
