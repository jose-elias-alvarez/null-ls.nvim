local u = require("null-ls.utils")

local export_tables = {
    diagnostics = {},
    formatting = {},
    code_actions = {},
    hover = {},
    completion = {},
    _test = {},
}

for method, table in pairs(export_tables) do
    setmetatable(table, {
        __index = function(t, k)
            local ok, builtin = pcall(require, string.format("null-ls.builtins.%s.%s", method, k))
            if not ok then
                u.echo(
                    "WarningMsg",
                    string.format("failed to load builtin %s for method %s; please check your config", k, method)
                )
                return
            end

            rawset(t, k, builtin)
            return builtin
        end,
    })
end

return setmetatable({}, {
    __index = function(_, k)
        return export_tables[k]
    end,
})
