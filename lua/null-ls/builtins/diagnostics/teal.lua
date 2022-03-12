local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "teal",
    meta = {
        url = "https://github.com/teal-language/tl",
        description = "The compiler for Teal, a typed dialect of Lua.",
    },
    method = DIAGNOSTICS,
    filetypes = { "teal" },
    generator_opts = {
        command = "tl",
        args = { "check", "$FILENAME" },
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        from_stderr = true,
        to_temp_file = true,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[:(%d+):(%d+): (.* ['"]?([%w%.%-]+)['"]?)$]], --
                groups = { "row", "col", "message", "_quote" },
                overrides = {
                    adapters = { h.diagnostics.adapters.end_col.from_quote },
                    diagnostic = { source = "tl check" },
                },
            },
            {
                pattern = [[:(%d+):(%d+): (.*)]], --
                groups = { "row", "col", "message" },
                overrides = { diagnostic = { source = "tl check" } },
            },
        }),
    },
    factory = h.generator_factory,
})
