local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
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
    },
})
