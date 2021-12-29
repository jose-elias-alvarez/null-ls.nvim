local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    method = CODE_ACTION,
    filetypes = { "lua" },
    generator_opts = {
        command = "bash",
        args = { "./test/scripts/sleep-and-echo.sh" },
        timeout = 100,
        on_output = function(params, done)
            if not params.output then
                return done()
            end

            return done({
                {
                    title = "Slow mock action",
                    action = function()
                        print("I took too long!")
                    end,
                },
            })
        end,
    },
    factory = h.generator_factory,
})
