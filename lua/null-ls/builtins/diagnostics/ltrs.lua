local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local handle_ltrs_output = function(params)
    local file = params.output
    if file and file.matches then
        local parser = h.diagnostics.from_json({
            severities = {
                ERROR = h.diagnostics.severities.error,
            },
        })

        local offenses = {}

        for _, m in ipairs(file.matches) do
            local tip = table.concat(
                vim.tbl_map(function(r)
                    return "“" .. r.value .. "”"
                end, m.replacements),
                ", "
            )

            table.insert(offenses, {
                message = m.message .. " Try: " .. tip,
                ruleId = m.rule.id,
                level = "ERROR",
                line = m.moreContext.line_number,
                column = m.moreContext.line_offset + 1,
                endLine = m.moreContext.line_number,
                endColumn = m.moreContext.line_offset + m.length + 1,
            })
        end

        return parser({ output = offenses })
    end

    return {}
end

return h.make_builtin({
    name = "ltrs",
    meta = {
        url = "https://github.com/jeertmans/languagetool-rust",
        description = "LanguageTool-Rust (LTRS) is both an executable and a Rust library that aims to provide correct and safe bindings for the LanguageTool API.",
    },
    method = DIAGNOSTICS,
    filetypes = { "text", "markdown", "markdown" },
    generator_opts = {
        command = "ltrs",
        args = { "check", "-m", "-r", "--text", "$TEXT" },
        format = "json",
        check_exit_code = function(c)
            return c <= 1
        end,
        on_output = handle_ltrs_output,
    },
    factory = h.generator_factory,
})
