local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "markdown" },
    generator_opts = {
        command = "ls",
        on_output = function(_, done)
            return done({
                {
                    message = "Lua diagnostic",
                    filename = vim.fn.getcwd() .. "/test/files/test-file.lua",
                    severity = 1,
                },
                {
                    message = "JavaScript diagnostic",
                    filename = vim.fn.getcwd() .. "/test/files/test-file.js",
                    severity = 1,
                },
            })
        end,
        multiple_files = true,
    },
    factory = h.generator_factory,
})
