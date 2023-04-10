local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "treefmt",
    meta = {
        url = "https://github.com/numtide/treefmt",
        description = "One CLI to format your repo",
        usage = [[
local sources = {
    null_ls.builtins.formatting.treefmt.with({
        -- treefmt requires a config file
        condition = function(utils)
            return utils.root_has_file("treefmt.toml")
        end,
    }),
}]],
    },
    method = FORMATTING,
    filetypes = {},
    generator_opts = {
        command = "treefmt",
        args = { "--allow-missing-formatter", "--stdin", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
