local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "prettier_standard",
    meta = {
        url = "https://github.com/sheerun/prettier-standard",
        description = "Formats with Prettier and lints with ESLint+Standard! (✿◠‿◠)",
    },
    method = FORMATTING,
    filetypes = { "javascript", "javascriptreact" },
    generator_opts = {
        command = "prettier-standard",
        args = { "--stdin" },
        to_stdin = true,
        dynamic_command = cmd_resolver.from_node_modules,
    },
    factory = h.formatter_factory,
})
