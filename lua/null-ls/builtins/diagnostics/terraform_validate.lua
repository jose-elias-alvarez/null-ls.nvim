local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    name = "terraform_validate",
    meta = {
        url = "https://github.com/hashicorp/terraform",
        description = "Terraform validate is is a subcommand of terraform to validate configuration files in a directory",
    },
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "terraform", "tf", "terraform-vars" },
    generator_opts = {
        command = "terraform",
        args = {
            "validate",
            "-json",
        },
        cwd = h.cache.by_bufnr(function(params)
            return vim.fs.dirname(params.bufname)
        end),
        from_stderr = true,
        to_stdin = false,
        multiple_files = true,
        format = "json",
        check_exit_code = function(_code, _stderr)
            -- check for warnings even if there are no errors
            return false
        end,
        on_output = function(params)
            local combined_diagnostics = {}

            -- keep diagnostics from other directories
            if params.source_id ~= nil then
                local namespace = require("null-ls.diagnostics").get_namespace(params.source_id)
                local old_diagnostics = vim.diagnostic.get(nil, { namespace = namespace })
                for _, old_diagnostic in ipairs(old_diagnostics) do
                    if not vim.startswith(old_diagnostic.filename, params.cwd) then
                        table.insert(combined_diagnostics, old_diagnostic)
                    end
                end
            end

            for _, new_diagnostic in ipairs(params.output.diagnostics) do
                local message = new_diagnostic.summary
                if new_diagnostic.detail then
                    message = message .. " - " .. new_diagnostic.detail
                end
                local rewritten_diagnostic = {
                    message = message,
                    row = 0,
                    col = 0,
                    source = "terraform validate",
                    severity = h.diagnostics.severities[new_diagnostic.severity],
                    filename = params.bufname,
                }
                if new_diagnostic.range ~= nil then
                    rewritten_diagnostic.col = new_diagnostic.range.start.column
                    rewritten_diagnostic.end_col = new_diagnostic.range["end"].column
                    rewritten_diagnostic.row = new_diagnostic.range.start.line
                    rewritten_diagnostic.end_row = new_diagnostic.range["end"].line
                    rewritten_diagnostic.filename = u.path.join(params.cwd, new_diagnostic.range.filename)
                end
                table.insert(combined_diagnostics, rewritten_diagnostic)
            end
            return combined_diagnostics
        end,
    },
    factory = h.generator_factory,
})
