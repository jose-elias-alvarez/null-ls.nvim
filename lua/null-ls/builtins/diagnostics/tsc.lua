local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

return h.make_builtin({
    method = methods.internal.DIAGNOSTICS_ON_SAVE,
    filetypes = { "typescript", "typescriptreact" },
    generator_opts = {
        command = "tsc",
        args = {
            "--pretty",
            "false",
            "--noEmit",
        },
        from_stderr = true,
        format = "line",
        multiple_files = true,
        on_output = function(line, params)
            local name, row, col, err, code, message = line:match("(%g+)%((%d+),(%d+)%): (%a+) (%g+): (.+)")
            if not (name and row and col) then
                return
            end

            local severity = err == "error" and 1 or 2
            return {
                row = row,
                col = col,
                code = code,
                message = message,
                severity = severity,
                filename = u.path.join(params.root, name),
            }
        end,
        cwd = function(params)
            return u.root_pattern("tsconfig.json")(params.bufname)
        end,
        timeout = 150000,
    },
    factory = h.generator_factory,
})
