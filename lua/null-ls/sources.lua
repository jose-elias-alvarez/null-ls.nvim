local validate = vim.validate

local M = {}

M.is_available = function(source, filetype, method)
    if source.generator._failed then
        return false
    end

    return (not filetype or source.filetypes["_all"] or source.filetypes[filetype])
        and (not method or source.methods[method])
end

M.validate_and_transform = function(source)
    if type(source) == "function" then
        source = source()
        if not source then
            return
        end
    end

    local generator, name = source.generator, source.name or "anonymous source"
    generator.opts = generator.opts or {}
    local methods = type(source.method) == "table" and source.method or { source.method }
    local filetypes = source.filetypes

    validate({
        generator = { generator, "table" },
        filetypes = { filetypes, "table" },
        name = { name, "string" },
        methods = { methods, "table" },
        fn = { generator.fn, "function" },
        opts = { generator.opts, "table" },
        async = { generator.async, "boolean", true },
        method = {
            methods,
            function(m)
                return not vim.tbl_isempty(m), "at least one method"
            end,
        },
    })

    -- use map for filetypes and methods to simplify checks
    local filetype_map, method_map = {}, {}
    if vim.tbl_isempty(filetypes) then
        filetype_map["_all"] = true
    else
        for _, ft in ipairs(filetypes) do
            filetype_map[ft] = true
        end
    end

    for _, method in ipairs(methods) do
        validate({
            method = {
                method,
                function(m)
                    return require("null-ls.methods").internal[m] ~= nil
                end,
                "supported null-ls method",
            },
        })
        method_map[method] = true
    end

    return {
        name = name,
        generator = generator,
        filetypes = filetype_map,
        methods = method_map,
    }
end

return M
