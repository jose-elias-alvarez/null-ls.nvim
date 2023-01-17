local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "terraform_fmt",
    meta = {
        url = "https://www.terraform.io/docs/cli/commands/fmt.html",
        description = "The terraform-fmt command rewrites `terraform` configuration files to a canonical format and style.",
    },
    method = FORMATTING,
    filetypes = { "terraform", "tf", "terraform-vars" },
    generator_opts = {
        command = "terraform",
        args = {
            "fmt",
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
