local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    name = "golangci_lint",
    meta = {
        url = "https://golangci-lint.run/",
        description = "A Go linter aggregator.",
    },
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "go" },
    generator_opts = {
        command = "golangci-lint",
        to_stdin = true,
        from_stderr = false,
        ignore_stderr = true,
        args = {
            "run",
            "--fix=false",
            "--fast",
            "--out-format=json",
            "$DIRNAME",
            "--path-prefix",
            "$ROOT",
        },
        format = "json",
        check_exit_code = function(code)
            return code <= 2
        end,
        on_output = function(params)
            local diags = {}
            local issues = params.output["Issues"]
            if type(issues) == "table" then
                for _, d in ipairs(issues) do
                    if d.Pos.Filename == params.bufname then
                        table.insert(diags, {
                            source = string.format("golangci-lint:%s", d.FromLinter),
                            row = d.Pos.Line,
                            col = d.Pos.Column,
                            message = d.Text,
                            severity = h.diagnostics.severities["warning"],
                        })
                    end
                end
            end
            return diags
        end,
    },
    factory = h.generator_factory,
})
