local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local PROJECT_DIAGNOSTICS = methods.internal.PROJECT_DIAGNOSTICS

return h.make_builtin({
    method = PROJECT_DIAGNOSTICS,
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
        on_output = function(line, params)
            local name, row, col, err, code, message = line:match("(%g+)%((%d+),(%d+)%): (%a+) (%g+): (.+)")
            if not (name and row and col) then
                return
            end

            local filename = require("lspconfig.util").path.join(params.root, name)
            local severity = err == "error" and 1 or 2
            return { row = row, col = col, code = code, message = message, severity = severity, filename = filename }
        end,
        timeout = 150000,
        cwd = function(params)
            return require("lspconfig.util").root_pattern("tsconfig.json")(params.bufname)
        end,
    },
    factory = h.generator_factory,
})
