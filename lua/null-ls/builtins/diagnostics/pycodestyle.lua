local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "pycodestyle",
    meta = {
        url = "https://github.com/PyCQA/pycodestyle",
        description = "pycodestyle is a tool to check your Python code against some of the style conventions in PEP 8.",
    },
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "pycodestyle",
        args = { "$FILENAME" },
        format = "line",

        -- pycodestyle returns 0 if there are no errors and warnings else it will return 1
        check_exit_code = function(code)
            return code == 0
        end,

        -- to allow null-ls to refresh pycodestyle diagnostics
        to_temp_file = true,

        -- pycodestyle outputs diagnostics to stderr, so we need to read from stderr to get the diagnostics
        from_stderr = true,
        on_output = h.diagnostics.from_pattern(
            [[:(%d+):(%d+): ((%u)%w+) (.*)]],
            { "row", "col", "code", "severity", "message" },
            {
                severities = {
                    -- Codes that start with E e.g. E122, E901 are treated as Errors
                    E = h.diagnostics.severities["error"],

                    -- Codes that start with W e.g. W601, W605 are treated as Warnings
                    W = h.diagnostics.severities["warning"],
                },
            }
        ),
    },
    factory = h.generator_factory,
})
