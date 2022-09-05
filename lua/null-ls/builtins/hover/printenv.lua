local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local HOVER = methods.internal.HOVER

return h.make_builtin({
    name = "printenv",
    method = HOVER,
    filetypes = { "sh", "dosbatch", "ps1" },
    generator = {
        fn = function(_, done)
            -- Get word under cursor
            local cword = vim.fn.expand("<cword>")

            -- Checks if cword is an environment variable
            -- If cword is environment variable and value not nil, show in hover window value of environment variable
            -- Else show in hover window "Error! `cword` is not an environment variable!"
            local ok, value = pcall(vim.loop.os_getenv, cword)
            if ok and (value ~= nil) then
                done({ cword .. ": " .. value })
            else
                done({ "Error! " .. cword .. " is not an environment variable!" })
            end
        end,
        async = true,
    },
    meta = {
        description = "Shows the value for the current environment variable under the cursor.",
        notes = {
            "This source is similar in function to `printenv` where it shows value of environment variable, however this source uses `vim.loop.os_getenv` instead of `printenv` thus making it cross-platform.",
        },
    },
})
