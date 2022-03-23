local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local client_id
local get_client = function()
    for _, client in ipairs(vim.lsp.get_active_clients()) do
        if client.name == "tsserver" then
            return client
        end
    end
end

return h.make_builtin({
    name = "tsc",
    meta = {
        url = "https://www.typescriptlang.org/docs/handbook/compiler-options.html",
        description = "Parses diagnostics from the TypeScript compiler.",
    },
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

            if not client_id then
                local client = get_client()
                if client and not client.is_stopped() then
                    client_id = client.id
                else
                    client_id = nil
                end
            end

            local filename = u.path.join(params.cwd, name)
            local bufnr = vim.fn.bufadd(filename)
            -- if tsserver client exists and is attached to buffer, don't duplicate diagnostics
            if client_id and vim.lsp.buf_is_attached(bufnr, client_id) then
                return
            end

            local severity = err == "error" and 1 or 2
            return {
                row = row,
                col = col,
                code = code,
                message = message,
                severity = severity,
                filename = filename,
            }
        end,
        cwd = function(params)
            return u.root_pattern("tsconfig.json")(params.bufname)
        end,
        timeout = 150000,
    },
    factory = h.generator_factory,
})
