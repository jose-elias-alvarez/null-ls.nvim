local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

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
        on_output = function(line, params)
            local name, row, col, err, code, message = line:match("(%g+)%((%d+),(%d+)%): (%a+) (%g+): (.+)")
            if not (name and row and col) then
                return
            end

            local filename = require("lspconfig.util").path.join(params.root, name)
            local tsserver_client_id
            for _, client in ipairs(vim.lsp.get_active_clients()) do
                if client.name == "tsserver" then
                    tsserver_client_id = client.id
                end
            end

            local bufnr = vim.fn.bufadd(filename)
            if tsserver_client_id and vim.lsp.buf_is_attached(bufnr, tsserver_client_id) then
                return
            end

            local severity = err == "error" and 1 or 2
            return {
                row = row,
                col = col,
                code = code,
                message = message,
                severity = severity,
                bufnr = bufnr,
            }
        end,
        timeout = 150000,
        cwd = function(params)
            return require("lspconfig.util").root_pattern("tsconfig.json")(params.bufname)
        end,
    },
    factory = h.generator_factory,
})
