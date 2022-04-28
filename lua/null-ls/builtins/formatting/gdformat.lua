local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING
-- local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

return h.make_builtin({
    name = "gdformat",
    meta = {
        url = "https://github.com/Scony/godot-gdscript-toolkit",
        description = "A formatter for Godot's gdscript",
    },
    method = { FORMATTING },
    filetypes = { "gd", "gdscript", "gdscript3" },
    generator_opts = {
        command = "gdformat",
        args = {
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
