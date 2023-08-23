local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "ghdl",
    meta = {
        url = "https://github.com/ghdl/ghdl",
        description = "Adds support for `ghdl` VHDL compiler/checker",
    },
    method = DIAGNOSTICS,
    filetypes = { "vhdl" },
    generator_opts = {
        command = "ghdl",
        to_stdin = false,
        to_temp_file = true,
        from_stderr = true,
        args = { "-a", "--std=08", "--workdir=/tmp", "$FILENAME" },
        format = "line",
        on_output = h.diagnostics.from_pattern(
        [[([^:]+):(%d+):(%d+):%s+(.+)]],
        { 'filename', 'row', 'col', 'message'},
        {
            severities = {
                E = h.diagnostics.severities["error"],
            },
        }
        ),
    },
    factory = h.generator_factory,
})
