local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local handle_opacheck_output = function(params)
    local diags = {}
    if params.output.errors == nil then
        return diags
    end
    for _, d in ipairs(params.output.errors) do
        if d.location ~= nil then
            table.insert(diags, {
                row = d.location.row,
                col = d.location.col,
                source = "opacheck",
                message = d.message,
                severity = vim.diagnostic.severity.ERROR,
                filename = d.location.file,
                code = d.code,
            })
        end
    end
    return diags
end

return h.make_builtin({
    name = "opacheck",
    meta = {
        url = "https://www.openpolicyagent.org/docs/latest/cli/#opa-check",
        description = "Check Rego source files for parse and compilation errors.",
    },
    method = methods.internal.DIAGNOSTICS_ON_SAVE,
    filetypes = { "rego" },
    generator_opts = {
        command = "opa",
        args = { "check", "-f", "json", "--strict", "$ROOT/src/", "$ROOT/test/" },
        format = "json",
        check_exit_code = function(code)
            return code <= 1
        end,
        from_stderr = true,
        multiple_files = true,
        on_output = handle_opacheck_output,
    },
    factory = h.generator_factory,
})
