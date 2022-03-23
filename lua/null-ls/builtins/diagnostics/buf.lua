local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "buf-lint",
    meta = {
        url = "https://github.com/bufbuild/buf",
        description = "A new way of working with Protocol Buffers.",
    },
    method = DIAGNOSTICS,
    filetypes = { "proto" },
    generator_opts = {
        command = "buf lint",
        args = { "$FILENAME", "#include_package_files=true" },
        from_stderr = true,
        to_temp_file = true,
        format = "raw",
        check_exit_code = function(code)
            return code <= 1
        end,
    },
    factory = h.generator_factory,
})
