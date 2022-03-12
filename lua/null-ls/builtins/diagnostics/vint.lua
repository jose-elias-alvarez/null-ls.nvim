local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "vint",
    meta = {
        url = "https://github.com/Vimjas/vint",
        description = "Linter for Vimscript.",
    },
    method = DIAGNOSTICS,
    filetypes = { "vim" },
    generator_opts = {
        command = "vint",
        format = "json",
        args = { "--style-problem", "--json", "$FILENAME" },
        to_stdin = false,
        to_temp_file = true,
        check_exit_code = function(code)
            return code == 0 or code == 1
        end,
        on_output = h.diagnostics.from_json({
            attributes = {
                row = "line_number",
                col = "column_number",
                code = "policy_name",
                severity = "severity",
                message = "description",
            },
            severities = {
                style_problem = h.diagnostics.severities["information"],
            },
        }),
    },
    factory = h.generator_factory,
})
