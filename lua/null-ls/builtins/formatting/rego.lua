local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "rego",
    meta = {
        url = "https://www.openpolicyagent.org/docs/latest/policy-language",
        description = " Rego (opa fmt) Formatter",
    },
    method = FORMATTING,
    filetypes = { "rego" },
    generator_opts = {
        command = "opa",
        args = { "fmt" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
