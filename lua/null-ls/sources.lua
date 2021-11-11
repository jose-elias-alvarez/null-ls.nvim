local validate = vim.validate

local M = {}

M.is_available = function(source, filetype, method)
    if source.generator._failed then
        return false
    end

    return (not filetype or source.filetypes["_all"] or source.filetypes[filetype])
        and (not method or source.methods[method])
end

M.get_available = function(filetype, method)
    local available = {}
    for _, source in ipairs(M.get_all()) do
        if M.is_available(source, filetype, method) then
            table.insert(available, source)
        end
    end
    return available
end

M.get_all = function()
    return require("null-ls.config").get()._sources
end

M.get_filetypes = function()
    local filetypes = {}
    for _, source in ipairs(M.get_all()) do
        for ft in pairs(source.filetypes) do
            if ft ~= "_all" and not vim.tbl_contains(filetypes, ft) then
                table.insert(filetypes, ft)
            end
        end
    end
    return filetypes
end

M.deregister = function(query)
    query = type(query) == "string" and { name = vim.pesc(query) } or query
    local name, method, id = query.name, query.method, query.id

    local matches_query = function(source)
        local name_matches = name == nil and true or source.name:find(name)
        local method_matches = method == nil and true or source.methods[method]
        local id_matches = id == nil and true or source.id == id
        return name_matches and method_matches and id_matches
    end

    local all_sources = M.get_all()
    -- iterate backwards to remove in loop
    for i = #all_sources, 1, -1 do
        if matches_query(all_sources[i]) then
            table.remove(all_sources, i)
        end
    end
end

local source_id = 0
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

    source_id = source_id + 1
    return {
        name = name,
        generator = generator,
        filetypes = filetype_map,
        methods = method_map,
        id = source_id,
    }
end

return M
