local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "stylelint",
    method = FORMATTING,
    filetypes = { "scss", "less", "css", "sass" },
    generator_opts = {
        command = "stylelint",
        args = { "--fix", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        dynamic_command = cmd_resolver.from_node_modules,
    },
    factory = h.formatter_factory,
})
