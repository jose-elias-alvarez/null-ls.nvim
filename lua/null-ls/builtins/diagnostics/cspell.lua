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
        description = "cspell is a spell checker for code.",
    },
    method = DIAGNOSTICS,
    filetypes = {},
    generator_opts = {
        command = "cspell",
        args = function(params)
            return {
                "lint",
                "--show-suggestions",
                "--language-id",
                params.ft,
                "stdin",
            }

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
        on_output = h.diagnostics.from_pattern(
            ".*:(%d+):(%d+)%s*-%s*(.*%((.*)%))%s*Suggestions:%s*%[(.*)%]",
            { "row", "col", "message", "_quote", "_suggestions" },
            {
                adapters = {
                    h.diagnostics.adapters.end_col.from_quote,
                    custom_user_data,
                },
            }
        ),
    },
    factory = h.generator_factory,
})
