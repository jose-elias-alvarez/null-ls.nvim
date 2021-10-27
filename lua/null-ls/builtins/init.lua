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
            if ok then
                rawset(t, k, builtin)
            end
            return builtin
        end,
    })
end

return setmetatable({}, {
    __index = function(_, k)
        return export_tables[k]
    end,
})
