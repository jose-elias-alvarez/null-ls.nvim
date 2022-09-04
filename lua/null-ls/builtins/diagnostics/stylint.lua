local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "stylint",
    meta = {
        url = "https://github.com/SimenB/stylint",
        description = [[A linter for the Stylus CSS preprocessor.]],
    },
    method = DIAGNOSTICS,
    filetypes = { "stylus" },
    generator_opts = {
        command = "stylint",
        args = { "$FILENAME" },
        to_stdin = true,
        from_stderr = false,
        format = "line",
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[^(%d+)  (%w+)  (.+)  +%w]],
                groups = { "row", "severity", "message" },
            },
            {
                pattern = [[^(%d+):(%d+)  (%w+)  (.+)  +%w]],
                groups = { "row", "col", "severity", "message" },
            },
        }),
        dynamic_command = cmd_resolver.from_node_modules,
    },
    factory = h.generator_factory,
})
