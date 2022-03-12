local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "shellharden",
    meta = {
        url = "https://github.com/anordal/shellharden",
        description = [[Hardens shell scripts by quoting variables, replacing `function_call` with `$(function_call)`, and more.]],
    },
    method = FORMATTING,
    filetypes = {
        "sh",
    },
    generator_opts = {
        command = "shellharden",
        args = { "--transform", "" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
