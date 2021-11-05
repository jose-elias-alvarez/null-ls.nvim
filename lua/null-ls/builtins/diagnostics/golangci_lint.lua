M.golangci_lint = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "go" },
    generator_opts = {
        command = "golangci-lint",
        to_stdin = true,
        from_stderr = false,
        args = {
            "run",
            "--fast",
            "--out-format",
            "json",
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
            for _, d in ipairs(params.output.Issues) do
                print(d.Pos.Filename)
                if d.Pos.Filename == params.bufname then
                    table.insert(diags, {
                        row = d.Pos.Line,
                        col = d.Pos.Column,
                        message = d.Text,
                    })
                end
            end
            return diags
        end,
    },
    factory = h.generator_factory,
})
