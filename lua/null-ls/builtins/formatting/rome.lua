local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "rome",
    meta = {
        url = "https://rome.tools",
        description = "Formatter, linter, bundler, and more for JavaScript, TypeScript, JSON, HTML, Markdown, and CSS.",
        notes = {
            "Currently support only JavaScript, TypeScript and JSON. See status [here](https://rome.tools/#language-support)",
        },
    },
    method = FORMATTING,
    filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact", "json" },
    generator_opts = {
        command = "rome",
        args = {
            "format",
            "--write",
            "$FILENAME",
        },
        dynamic_command = cmd_resolver.from_node_modules(),
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern(
                -- https://docs.rome.tools/configuration/
                "rome.json"
            )(params.bufname)
        end),
        to_stdin = false,
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
