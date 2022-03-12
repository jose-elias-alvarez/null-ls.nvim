local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

return h.make_builtin({
    name = "stylua",
    meta = {
        url = "https://github.com/JohnnyMorganz/StyLua",
        description = "An opinionated code formatter for Lua.",
    },
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = { "lua" },
    generator_opts = {
        command = "stylua",
        args = h.range_formatting_args_factory({
            "--search-parent-directories",
            "--stdin-filepath",
            "$FILENAME",
            "-",
        }, "--range-start", "--range-end", { row_offset = -1, col_offset = -1 }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
