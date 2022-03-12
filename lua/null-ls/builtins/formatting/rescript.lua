local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local cmd_resolver = require("null-ls.helpers.command_resolver")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "rescript",
    meta = {
        url = "https://rescript-lang.org/",
        description = "The ReScript format builtin.",
    },
    method = FORMATTING,
    filetypes = {
        "rescript",
    },
    generator_opts = {
        command = "rescript",
        args = function(params)
            return { "format", "-stdin", "." .. vim.fn.fnamemodify(params.bufname, ":e") }
        end,
        dynamic_command = cmd_resolver.from_node_modules,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
