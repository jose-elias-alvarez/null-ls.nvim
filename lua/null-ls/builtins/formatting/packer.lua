local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "packerfmt",
    meta = {
        url = "https://www.packer.io/docs/commands/fmt",
        description = "The packer fmt Packer command is used to format HCL2 configuration files to a canonical format and style.",
    },
    method = FORMATTING,
    filetypes = { "hcl" },
    generator_opts = {
        command = "packer",
        args = {
            "fmt",
            "-",
        },
        to_stdin = true,
        runtime_condition = function(params)
            -- only target packer hcl files
            return params.bufname:match("%.pkr%.hcl") ~= nil
        end,
    },
    factory = h.formatter_factory,
})
