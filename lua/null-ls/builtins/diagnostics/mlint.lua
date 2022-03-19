local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

-- Using DIAGNOSTICS_ON_SAVE on save here because mlint will not lint files with
-- invalid filenames. The temp file stored by null-ls is of the form
-- `/tmp/null-ls_xxxxxx`, which contains the `-` character and Matlab does not
-- allow this character in filenames.
local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    name = "mlint",
    meta = {
        url = "https://www.mathworks.com/help/matlab/ref/mlint.html",
        description = "Linter for MATLAB files",
    },
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "matlab" },
    generator_opts = {
        command = "mlint",
        args = { "$FILENAME" },
        from_stderr = true,
        format = "line",
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[L (%d+) .C (%d+).*: (.*)]],
                groups = { "row", "col", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})
