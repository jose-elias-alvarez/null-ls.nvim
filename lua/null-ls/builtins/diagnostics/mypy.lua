local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local overrides = {
    severities = {
        error = h.diagnostics.severities["error"],
        warning = h.diagnostics.severities["warning"],
        note = h.diagnostics.severities["information"],
    },
}

return h.make_builtin({
    name = "mypy",
    meta = {
        url = "https://github.com/python/mypy",
        description = [[Mypy is an optional static type checker for Python that aims to combine the
benefits of dynamic (or "duck") typing and static typing.]],
    },
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "mypy",
        args = function(params)
            return {
                "--hide-error-codes",
                "--hide-error-context",
                "--no-color-output",
                "--show-column-numbers",
                "--show-error-codes",
                "--no-error-summary",
                "--no-pretty",
                "--shadow-file",
                params.bufname,
                params.temp_path,
                params.bufname,
            }
        end,
        to_temp_file = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 2
        end,
        multiple_files = true,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = "([^:]+):(%d+):(%d+): (%a+): (.*)  %[([%a-]+)%]",
                groups = { "filename", "row", "col", "severity", "message", "code" },
                overrides = overrides,
            },
            {
                pattern = "([^:]+):(%d+): (%a+): (.*)",
                groups = { "filename", "row", "severity", "message" },
                overrides = overrides,
            },
        }),
    },
    factory = h.generator_factory,
})
