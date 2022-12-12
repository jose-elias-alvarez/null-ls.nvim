local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION
local range_actions = { ["reset_hunk"] = true, ["stage_hunk"] = true }

return h.make_builtin({
    name = "gitsigns",
    meta = {
        url = "https://github.com/lewis6991/gitsigns.nvim",
        description = "Injects code actions for Git operations at the current cursor position (stage / preview / reset hunks, blame, etc.).",
        config = {
            {
                key = "filter_actions",
                type = "function",
                description = "Callback to filter out unwanted actions.",
                usage = [[
function(title)
    return title:lower():match("blame") == nil -- filter out blame actions
end,]],
            },
        },
    },
    method = CODE_ACTION,
    filetypes = {},
    can_run = function()
        local status, _ = pcall(require, "gitsigns")

        return status
    end,
    generator = {
        fn = function(params)
            local ok, gitsigns_actions = pcall(require("gitsigns").get_actions)
            if not ok or not gitsigns_actions then
                return
            end

            local filter_actions = params:get_config().filter_actions

            local name_to_title = function(name)
                return name:sub(1, 1):upper() .. name:gsub("_", " "):sub(2)
            end

            local actions = {}
            local mode = vim.api.nvim_get_mode().mode
            for name, action in pairs(gitsigns_actions) do
                local title = name_to_title(name)
                if not filter_actions or filter_actions(title) then
                    local cb = action
                    if (mode == "v" or mode == "V") and range_actions[name] then
                        title = title:gsub("hunk", "selection")
                        cb = function()
                            action({ params.range.row, params.range.end_row })
                        end
                    end
                    table.insert(actions, {
                        title = title,
                        action = function()
                            vim.api.nvim_buf_call(params.bufnr, cb)
                        end,
                    })
                end
            end
            return actions
        end,
    },
})
