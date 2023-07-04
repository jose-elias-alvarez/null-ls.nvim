local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "haxe_formatter",
    meta = {
        url = "https://github.com/HaxeCheckstyle/haxe-formatter",
        description = "Haxe code formatter based on tokentree",
    },
    method = FORMATTING,
    filetypes = { "haxe" },
    generator_opts = {
        command = "haxelib",
        args = {
            "run",
            "formatter",
            "--stdin",
            "--source",
            "$FILENAME",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
