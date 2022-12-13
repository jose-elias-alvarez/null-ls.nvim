local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local handle_swiftlint_output = function(params)
    local parser = h.diagnostics.from_json({
        attributes = {
            severity = "severity",
            col = "character",
            code = "rule_id",
            message = "reason",
        },
        severities = {
            ["warning"] = "Warning",
            ["error"] = "Error",
        },
    })

    return parser({ output = params.output })
end

return h.make_builtin({
    name = "swiftlint",
    meta = {
        url = "https://github.com/realm/SwiftLint",
        description = "A tool to enforce Swift style and conventions.",
    },
    method = DIAGNOSTICS,
    filetypes = { "swift" },
    generator_opts = {
        command = "swiftlint",
        args = { "--reporter", "json", "--use-stdin", "--quiet" },
        to_stdin = true,
        format = "json",
        on_output = handle_swiftlint_output,
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern("Package.swift", ".git")(params.bufname)
        end),
    },
    factory = h.generator_factory,
})
