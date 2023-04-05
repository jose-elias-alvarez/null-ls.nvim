local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

return h.make_builtin({
    name = "reek",
    meta = {
        url = "https://github.com/troessner/reek",
        description = "Code smell detectory for Ruby",
    },
    method = methods.internal.DIAGNOSTICS_ON_SAVE,
    filetypes = { "ruby" },
    generator_opts = {
        command = "reek",
        args = { "-s", "$FILENAME" },
        format = "line",
        multiple_files = true,
        on_output = function(line, params)
            local name, row, code, message = line:match("%s+(%g+):(%d+): (%g+): (.+)%s*%f[[]")
            if not (name and row) then
                return
            end

            local filename = u.path.join(params.cwd, name)

            local severity = 2 -- warning
            return {
                row = row,
                code = code,
                message = message,
                severity = severity,
                filename = filename,
            }
        end,
    },
    factory = h.generator_factory,
})
