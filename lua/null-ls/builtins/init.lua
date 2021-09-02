local paths = {
    diagnostics = "null-ls.builtins.diagnostics",
    formatting = "null-ls.builtins.formatting",
    code_actions = "null-ls.builtins.code-actions",
    _test = "null-ls.builtins.test",
}

return setmetatable({}, {
    __index = function(t, k)
        local require_path = paths[k]
        if not require_path then
            return
        end

        local module = require(require_path)
        t[k] = module

        return module
    end,
})
