local methods = require("null-ls.methods")

return {
    method = methods.internal.CODE_ACTION,
    generator = {
        fn = function()
            return {
                {
                    title = "Mock action",
                    action = function()
                        print("I am a mock action!")
                    end,
                },
            }
        end,
    },
    filetypes = { "lua" },
}
