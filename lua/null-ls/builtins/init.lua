local logger = require("null-ls.logger")

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
                logger:warn(
                    string.format("failed to load builtin %s for method %s; please check your config", k, method)
                )
                return
            end

            rawset(t, k, builtin)
            return builtin
        end,
    })
end

return setmetatable(export_tables, {
    __index = function(t, k)
        if not rawget(t, k) then
            logger:warn(string.format("failed to load builtin table for method %s; please check your config", k))
        end

        return rawget(t, k)
    end,
})
