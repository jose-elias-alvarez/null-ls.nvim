local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "nixpkgs_fmt",
    meta = {
        url = "https://github.com/nix-community/nixpkgs-fmt",
        description = "nixpkgs-fmt is a Nix code formatter for nixpkgs.",
    },
    method = FORMATTING,
    filetypes = { "nix" },
    generator_opts = {
        command = "nixpkgs-fmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
