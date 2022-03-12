local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "astyle",
    meta = {
        url = "http://astyle.sourceforge.net/",
        description = [[Artistic Style is a source code indenter, formatter, and beautifier for the C, C++, C++/CLI, Objective‑C, C# and Java programming languages. This formatter works well for [Arduino](https://www.arduino.cc/) project files and is the same formatter used in the Arduino IDE.]],
    },
    method = FORMATTING,
    filetypes = { "arduino", "c", "cpp", "cs", "java" },
    generator_opts = {
        command = "astyle",
        args = {
            "--quiet",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
