local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "stylelint",
    meta = {
        url = "https://github.com/stylelint/stylelint",
        description = "A mighty, modern linter that helps you avoid errors and enforce conventions in your styles.",
    },
    method = DIAGNOSTICS,
    filetypes = { "scss", "less", "css", "sass" },
    generator_opts = {
        command = "stylelint",
        args = { "--formatter", "json", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        format = "json_raw",
        from_stderr = true,
        dynamic_command = cmd_resolver.from_node_modules(),
        on_output = function(params)
            local output = params.output and params.output[1] and params.output[1].warnings or {}

            -- json decode failure means stylelint failed to run
            if params.err then
                table.insert(output, { text = params.output })
            end

            local parser = h.diagnostics.from_json({
                attributes = {
                    severity = "severity",
                    message = "text",
                },
                severities = {
                    h.diagnostics.severities["warning"],
                    h.diagnostics.severities["error"],
                },
            })

            params.output = output
            return parser(params)
        end,
    },
    factory = h.generator_factory,
})
