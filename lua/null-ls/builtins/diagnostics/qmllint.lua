local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "qml" },
    generator_opts = {
        command = "qmllint",
        args = { "--no-unqualified-id", "$FILENAME" },
        to_stdin = false,
        format = "raw",
        from_stderr = true,
        to_temp_file = true,
        on_output = h.diagnostics.from_errorformat(table.concat({ "%trror: %m", "%f:%l : %m" }, ","), "qmllint"),
    },
    factory = h.generator_factory,
})
