local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

return h.make_builtin({
    name = "cmake_lint",
    meta = {
        url = "https://github.com/cheshirekow/cmake_format",
        description = "Check cmake listfiles for style violations, common mistakes, and anti-patterns.",
    },
    method = methods.internal.DIAGNOSTICS_ON_SAVE,
    filetypes = { "cmake" },
    generator_opts = {
        command = "cmake-lint",
        args = {
            "$FILENAME",
        },
        format = "line",
        to_stdin = false,
        from_stderr = true,
        on_output = h.diagnostics.from_pattern(
            [[(%d+),(%d+): %[((%w)[%d]+)%] (.+)]],
            { "row", "col", "code", "severity", "message" },
            {
                severities = {
                    E = h.diagnostics.severities["error"],
                    W = h.diagnostics.severities["warning"],
                    C = h.diagnostics.severities["information"],
                    R = h.diagnostics.severities["information"],
                    I = h.diagnostics.severities["information"],
                },
                offsets = { col = 1 },
            }
        ),
    },
    factory = h.generator_factory,
})
