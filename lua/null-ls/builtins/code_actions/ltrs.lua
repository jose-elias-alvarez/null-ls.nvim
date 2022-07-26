local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

local handle_ltrs_output = function(params)
    local actions = {}

    for _, m in ipairs(params.output.matches) do
        if m.replacements ~= vim.NIL and params.row == m.moreContext.line_number then
            local row = m.moreContext.line_number - 1
            local col_beg = m.moreContext.line_offset
            local col_end = m.moreContext.line_offset + m.length

            for _, r in ipairs(m.replacements) do
                if string.find(r.value, "not shown") == nil then
                    table.insert(actions, {
                        title = "Replace with “" .. r.value .. "”",
                        action = function()
                            vim.api.nvim_buf_set_text(params.bufnr, row, col_beg, row, col_end, { r.value })
                        end,
                    })
                end
            end
        end
    end

    return actions
end

return h.make_builtin({
    name = "ltrs",
    meta = {
        url = "https://github.com/jeertmans/languagetool-rust",
        description = "LanguageTool-Rust (LTRS) is both an executable and a Rust library that aims to provide correct and safe bindings for the LanguageTool API.",
    },
    method = CODE_ACTION,
    filetypes = { "text", "markdown" },
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
