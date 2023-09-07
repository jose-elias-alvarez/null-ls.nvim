local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "deno_lint",
    meta = {
        url = "https://github.com/denoland/deno_lint",
        description = "Blazing fast linter for JavaScript and TypeScript written in Rust",
    },
    method = DIAGNOSTICS,
    filetypes = { "javascript", "typescript", "typescriptreact", "javascriptreact" },
    generator_opts = {
        command = "deno",
        args = { "lint", "--json", "$FILENAME" },
        format = "json",
        to_stdin = false,
        check_exit_code = function(c)
            return c <= 1
        end,
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern("deno.json", "deno.jsonc", "package.json", ".git")(params.bufname)
        end),
        on_output = function(params)
            local diags = {}

            for _, d in ipairs(params.output.errors) do
                table.insert(diags, {
                    row = 0,
                    col = 1,
                    message = d.message,
                    severity = 1,
                })
            end

            for _, d in ipairs(params.output.diagnostics) do
                local message = d.message
                if type(d.hint) == "string" then
                    message = message .. "\n" .. d.hint
                end

                table.insert(diags, {
                    row = d.range.start.line,
                    col = d.range.start.col + 1,
                    end_row = d.range["end"].line,
                    end_col = d.range["end"].col + 1,
                    code = d.code,
                    message = message,
                    severity = 2,
                })
            end
            return diags
        end,
    },
    factory = h.generator_factory,
})
