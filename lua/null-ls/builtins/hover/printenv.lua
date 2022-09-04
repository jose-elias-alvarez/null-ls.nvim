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

            -- Gets table of environment variables
            local env_vars = vim.fn.environ()

            -- Checks if cword is in table of environment variables
            -- If not in table of environment variables, show in hover window "Error! `cword` is not an environment variable!"
            -- Else show in hover window value of environment variable
            if env_vars[cword] == nil then
                done({ "Error! " .. cword .. " is not an environment variable!" })
            else
                done({ cword .. ": " .. env_vars[cword] })
            end
        end,
        async = true,
    },
    meta = {
        description = "Shows the value for the current environment variable under the cursor.",
        notes = {
            "This source is similar in function to `printenv` where it shows value of environment variable, however this source uses `vim.fn.environ()` instead of `printenv` thus making it cross-platform.",
        },
    },
})
