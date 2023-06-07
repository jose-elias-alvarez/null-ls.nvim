local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

return h.make_builtin({
    name = "nelua",
    meta = {
        url = "https://github.com/edubart/nelua",
        description = "Nelua can analize code using `nelua -a`.",
    },
    method = methods.internal.DIAGNOSTICS,
    filetypes = { "nelua" },
    generator_opts = {
        command = "nelua",
        args = { "-a", "$FILENAME", "-L", "$DIRNAME" },
        format = "line",
        to_stdin = false,
        from_stderr = true,
        to_temp_file = true,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(line, params)
            return h.diagnostics.from_pattern(
                [[(.*):(%d+):(%d+): (%w+): (.*)]],
                { "filename", "row", "col", "severity", "message" },
                {
                    severities = {
                        info = h.diagnostics.severities["information"],
                    },
                }
            )(
                -- don't match AST nodes information
                line:gsub([[.*:%d+:%d+: from: .*]], ""),
                params
            )
        end,
    },
    factory = h.generator_factory,
})
