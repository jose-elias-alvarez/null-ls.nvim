local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION
local ACTIONS = {
    p = "pick",
    r = "reword",
    e = "edit",
    s = "squash",
    f = "fixup",
    x = "exec",
    b = "break",
    d = "drop",
}

return h.make_builtin({
    name = "gitrebase",
    meta = {
        description = "Injects actions to change `gitrebase` command (e.g. using `squash` instead of `pick`).",
    },
    method = CODE_ACTION,
    filetypes = { "gitrebase" },
    generator = {
        fn = function(params)
            local lines = vim.api.nvim_buf_get_lines(params.bufnr, params.range.row - 1, params.range.row, true)
            local line = lines[1]
            local type = line:match("^(%a+)")

            local found = false
            local code_actions = {}
            for short, full in pairs(ACTIONS) do
                if short == type or full == type then
                    found = true
                else
                    table.insert(code_actions, {
                        title = full,
                        action = function()
                            local replacement = line:gsub("^(%a+)", full)
                            vim.api.nvim_buf_set_lines(
                                params.bufnr,
                                params.range.row - 1,
                                params.range.row,
                                true,
                                { replacement }
                            )
                        end,
                    })
                end
            end

            return found and code_actions or {}
        end,
    },
})
