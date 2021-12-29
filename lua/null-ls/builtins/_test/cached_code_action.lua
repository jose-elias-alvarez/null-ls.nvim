local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    method = CODE_ACTION,
    filetypes = { "text" },
    generator_opts = {
        command = "ls",
        on_output = function(params, done)
            return done({
                {
                    title = params._null_ls_cached and "Cached" or "Not cached",
                    action = function() end,
                },
            })
        end,
        use_cache = true,
    },
    factory = h.generator_factory,
})
