local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "xo",
    method = FORMATTING,
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    factory = h.generator_factory,
    generator_opts = {
        command = "xo",
        args = { "--fix", "--reporter", "json", "--stdin", "--stdin-filename", "$FILENAME" },
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
    },
})
