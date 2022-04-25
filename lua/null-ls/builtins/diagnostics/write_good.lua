local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "write_good",
    meta = {
        url = "https://github.com/btford/write-good",
        description = "English prose linter.",
    },
    method = DIAGNOSTICS,
    filetypes = { "markdown" },
    generator_opts = {
        command = "write-good",
        args = { "--text=$TEXT", "--parse" },
        format = "line",
        check_exit_code = { 0, 255 },
        on_output = h.diagnostics.from_pattern(
            [[(%d+):(%d+):("([%w%s]+)".*)]], --
            { "row", "col", "message", "_quote" },
            {
                adapters = { h.diagnostics.adapters.end_col.from_quote },
                offsets = { col = 1 },
            }
        ),
    },
    factory = h.generator_factory,
})
