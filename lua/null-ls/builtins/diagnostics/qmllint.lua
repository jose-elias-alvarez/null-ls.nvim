local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "qmllint",
    meta = {
        url = "https://doc-snapshots.qt.io/qt6-dev/qtquick-tools-and-utilities.html#qmllint",
        description = "qmllint is a tool shipped with Qt that verifies the syntatic validity of QML files. It also warns about some QML anti-patterns.",
    },
    method = DIAGNOSTICS,
    filetypes = { "qml" },
    generator_opts = {
        command = "qmllint",
        args = { "$FILENAME" },
        to_stdin = false,
        format = "raw",
        from_stderr = true,
        to_temp_file = true,
        on_output = h.diagnostics.from_errorformat(
            table.concat({
                "%trror: %f:%l:%c: %m",
                "%tarning: %f:%l:%c: %m",
            }, ","),
            "qmllint"
        ),
    },
    factory = h.generator_factory,
})
