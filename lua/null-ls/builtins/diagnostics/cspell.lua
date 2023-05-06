local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local custom_user_data = {
    user_data = function(entries, _)
        if not entries then
            return
        end

        local suggestions = {}
        for suggestion in string.gmatch(entries["_suggestions"], "[^, ]+") do
            table.insert(suggestions, suggestion)
        end

        return {
            suggestions = suggestions,
            misspelled = entries["_quote"],
        }
    end,
}

return h.make_builtin({
    name = "cspell",
    meta = {
        url = "https://github.com/streetsidesoftware/cspell",
        description = [[cspell is a spell checker for code.

**This source is not actively developed in this repository.**

An up-to-date version exists as a companion plugin in [cspell.nvim](https://github.com/davidmh/cspell.nvim)
]],
    },
    method = DIAGNOSTICS,
    filetypes = {},
    generator_opts = {
        command = "cspell",
        args = function(params)
            local cspell_args = {
                "lint",
                "--language-id",
                params.ft,
                "stdin",
            }

            -- only enable suggestions when using the code actions built-in, since they slow down the command
            local should_add_suggestions = not vim.tbl_isempty(require("null-ls").get_source({
                name = "cspell",
                method = methods.internal.CODE_ACTION,
            }))

            if should_add_suggestions then
                cspell_args = vim.list_extend({ "--show-suggestions" }, cspell_args)
            end

            return cspell_args
        end,
        to_stdin = true,
        ignore_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = ".*:(%d+):(%d+)%s*-%s*(.*%((.*)%))%s*Suggestions:%s*%[(.*)%]",
                groups = { "row", "col", "message", "_quote", "_suggestions" },
                overrides = {
                    adapters = {
                        h.diagnostics.adapters.end_col.from_quote,
                        custom_user_data,
                    },
                },
            },
            {
                pattern = [[.*:(%d+):(%d+)%s*-%s*(.*%((.*)%))]],
                groups = { "row", "col", "message", "_quote" },
                overrides = {
                    adapters = {
                        h.diagnostics.adapters.end_col.from_quote,
                    },
                },
            },
        }),
    },
    factory = h.generator_factory,
})
