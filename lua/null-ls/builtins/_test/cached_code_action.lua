local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

return h.make_builtin({
    method = methods.internal.CODE_ACTION,
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
