local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "eslint",
    meta = {
        url = "https://github.com/eslint/eslint",
        description = "Find and fix problems in your JavaScript code.",
        notes = {
            "Slow and not suitable for formatting on save. If at all possible, use [eslint_d](https://github.com/mantoni/eslint_d.js/).",
        },
    },
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
    },
    factory = h.generator_factory,
    generator_opts = {
        command = "eslint",
        args = { "--fix-dry-run", "--format", "json", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        format = "json",
        on_output = function(params)
            local parsed = params.output[1]
            return parsed
                and parsed.output
                and {
                    {
                        row = 1,
                        col = 1,
                        end_row = #vim.split(parsed.output, "\n") + 1,
                        end_col = 1,
                        text = parsed.output,
                    },
                }
        end,
        dynamic_command = cmd_resolver.from_node_modules,
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern(
                -- https://eslint.org/docs/user-guide/configuring/configuration-files#configuration-file-formats
                ".eslintrc",
                ".eslintrc.js",
                ".eslintrc.cjs",
                ".eslintrc.yaml",
                ".eslintrc.yml",
                ".eslintrc.json",
                "package.json"
            )(params.bufname)
        end),
    },
})
