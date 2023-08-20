local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "ts-standard",
    meta = {
        url = "https://github.com/standard/ts-standard",
        description = "Typescript style guide, linter, and formatter using StandardJS",
    },
    method = FORMATTING,
    filetypes = { "typescript", "typescriptreact" },
    generator_opts = {
        command = "ts-standard",
        args = { "--stdin", "--fix" },
        to_stdin = true,
        dynamic_command = cmd_resolver.from_node_modules,
    },
    factory = h.formatter_factory,
})
