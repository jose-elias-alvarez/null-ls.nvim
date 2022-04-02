local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "verible_verilog_format",
    meta = {
        url = "https://github.com/chipsalliance/verible",
        description = "The verible-verilog-format formatter manages whitespace in accordance with a particular style. The main goal is to relieve humans of having to manually manage whitespace, wrapping, and indentation, and to provide a tool that can be integrated into any editor to enable editor-independent consistency.",
    },
    method = FORMATTING,
    filetypes = { "verilog", "systemverilog" },
    generator_opts = {
        command = "verible-verilog-format",
        args = { "--stdin_name", "$FILENAME", "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
