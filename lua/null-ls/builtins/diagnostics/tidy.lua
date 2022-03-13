local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local severities = {
    Warning = vim.diagnostic.severity.WARN,
    Error = vim.diagnostic.severity.ERROR,
}

return h.make_builtin({
    name = "tidy",
    meta = {
        url = "https://www.html-tidy.org/",
        description = [[Tidy corrects and cleans up HTML and XML documents by ]]
            .. [[fixing markup errors and upgrading legacy code to modern standards.]],
    },
    method = DIAGNOSTICS,
    filetypes = { "html", "xml" },
    generator_opts = {
        command = "tidy",
        args = function(params)
            local common_args = {
                "--gnu-emacs",
                "yes",
                "-quiet",
                "-errors",
                "$FILENAME",
            }

            if params.ft == "xml" then
                table.insert(common_args, 1, "-xml")
            end

            return common_args
        end,
        to_stdin = true,
        from_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 2
        end,
        on_output = h.diagnostics.from_pattern(
            [[([^:]+):(%d+):(%d+): (%a+): (.+)]],
            { "file", "row", "col", "severity", "message" },
            { severities = severities }
        ),
    },
    factory = h.generator_factory,
})
