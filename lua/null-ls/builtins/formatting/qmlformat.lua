local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "qmlformat",
    meta = {
        url = "https://doc-snapshots.qt.io/qt6-dev/qtquick-tools-and-utilities.html#qmlformat",
        description = "qmlformat is a tool that automatically formats QML files according to the QML Coding Conventions.",
    },
    method = FORMATTING,
    filetypes = { "qml" },
    generator_opts = {
        command = "qmlformat",
        args = { "-i", "$FILENAME" },
        to_stdin = false,
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})
