local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

return h.make_builtin({
    name = "flawfinder",
    meta = {
        url = "https://dwheeler.com/flawfinder/",
        description = "Flawfinder, a simple program that examines C/C++ source code and reports possible security weaknesses (“flaws”) sorted by risk level.",
    },
    method = methods.internal.DIAGNOSTICS_ON_SAVE,
    filetypes = { "c", "cpp" },
    to_temp_file = true,
    generator = h.generator_factory({
        command = "flawfinder",
        args = {
            "-S",
            "-Q",
            "-D",
            "-C",
            "$FILENAME",
        },
        to_stdin = false,
        from_stderr = false,
        format = "line",
        on_output = h.diagnostics.from_pattern(
            [[^(.*):(%d+):(%d+): *%[([0-5])%] (.*)$]],
            { "file", "row", "col", "severity", "message" },
            {
                severities = {
                    ["5"] = vim.diagnostic.severity.WARN,
                    ["4"] = vim.diagnostic.severity.WARN,
                    ["3"] = vim.diagnostic.severity.WARN,
                    ["2"] = vim.diagnostic.severity.WARN,
                    ["1"] = vim.diagnostic.severity.WARN,
                },
            }
        ),
    }),
})
