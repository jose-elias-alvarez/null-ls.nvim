local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    name = "buf_lint",
    meta = {
        url = "https://github.com/bufbuild/buf",
        description = "A new way of working with Protocol Buffers.",
    },
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "proto" },
    generator_opts = {
        command = "buf",
        args = { "lint", "$FILENAME#include_package_files=true" },
        from_stderr = true,
        to_stdin = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[(.*):(%d+):(%d+):(.*)]],
                groups = { "filename", "row", "col", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})
