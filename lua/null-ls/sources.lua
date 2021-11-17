local methods = require("null-ls.methods")
local diagnostics = require("null-ls.diagnostics")
local log = require("null-ls.logger")
local u = require("null-ls.utils")

local validate = vim.validate

local registered = {
    names = {},
    sources = {},
    id = 0,
}

local M = {}

local matches_query = function(source, query)
    query = type(query) == "string" and { name = vim.pesc(query) } or query
    local name, method, id = query.name, query.method, query.id

    local name_matches = name == nil and true or source.name:find(name)
    local method_matches = method == nil and true or source.methods[method]
    local id_matches = id == nil and true or source.id == id
    return name_matches and method_matches and id_matches
end

local for_each_matching = function(query, cb)
    for _, source in ipairs(M.get_all()) do
        if matches_query(source, query) then
            cb(source)
        end
    end
end

local register_source = function(source)
    source = M.validate_and_transform(source)
    if not source then
        return
    end

    registered.id = registered.id + 1
    source.id = registered.id

    table.insert(registered.sources, source)
    registered.names[source.name] = true

    require("null-ls.lspconfig").on_register_source(source)
end

M.is_available = function(source, filetype, method)
    if source._disabled or source.generator._failed then
        return false
    end

    local filetype_matches = not filetype
        or source.filetypes["_all"] and source.filetypes[filetype] == nil
        or source.filetypes[filetype] == true

    local method_matches = not method or source.methods[method] == true
    if not method_matches and methods.overrides[method] then
        for m in pairs(methods.overrides[method]) do
            if source.methods[m] then
                method_matches = true
                break
            end
        end
    end

    return filetype_matches and method_matches
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

M.get = function(query)
    local matching = {}
    for_each_matching(query, function(source)
        table.insert(matching, source)
    end)

    return matching
end

M.enable = function(query)
    for_each_matching(query, function(source)
        source._disabled = false
        require("null-ls.lspconfig").on_register_source(source)
    end)
end

M.disable = function(query)
    for_each_matching(query, function(source)
        source._disabled = true
        diagnostics.hide_source_diagnostics(source.id)
    end)
end

M.toggle = function(query)
    for_each_matching(query, function(source)
        source._disabled = not source._disabled
        if source._disabled then
            diagnostics.hide_source_diagnostics(source.id)
        else
            require("null-ls.lspconfig").on_register_source(source)
        end
    end)
end

M.get_all = function()
    return registered.sources
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
    local all_sources = M.get_all()
    -- iterate backwards to remove in loop
    for i = #all_sources, 1, -1 do
        if matches_query(all_sources[i], query) then
            table.remove(all_sources, i)
        end
    end

    require("null-ls.lspconfig").on_register_sources()
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
    local source_methods = type(source.method) == "table" and source.method or { source.method }
    local filetypes, disabled_filetypes = source.filetypes, source.disabled_filetypes

    validate({
        generator = { generator, "table" },
        filetypes = { filetypes, "table" },
        disabled_filetypes = { disabled_filetypes, "table", true },
        name = { name, "string" },
        fn = { generator.fn, "function" },
        opts = { generator.opts, "table" },
        async = { generator.async, "boolean", true },
        method = {
            source_methods,
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

    if disabled_filetypes then
        for _, ft in ipairs(disabled_filetypes) do
            filetype_map[ft] = false
        end
    end

    for _, method in ipairs(source_methods) do
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

    if
        (method_map[methods.internal.DIAGNOSTICS_ON_SAVE] or method_map[methods.internal.PROJECT_DIAGNOSTICS])
        and not u.has_version("0.6.0")
    then
        log:warn(string.format("source %s is not supported on nvim versions < 0.6.0", name))
        return
    end

    return {
        name = name,
        generator = generator,
        filetypes = filetype_map,
        methods = method_map,
    }
end

M.register = function(to_register)
    if type(to_register) == "function" or (type(to_register) == "table" and to_register.method) then
        -- register a single source
        register_source(to_register)
    elseif not to_register.sources then
        -- register a simple list of sources
        for _, source in ipairs(to_register) do
            register_source(source)
        end
    else
        -- register multiple sources with shared configuration
        for _, source in ipairs(to_register.sources) do
            source.filetypes = to_register.filetypes or source.filetypes
            source.name = to_register.name or source.name

            register_source(source)
        end
    end

    require("null-ls.lspconfig").on_register_sources()
end

M.reset = function()
    registered.sources = {}
    registered.names = {}
    require("null-ls.lspconfig").on_register_sources()
end

M.is_registered = function(query)
    if type(query) == "string" and registered.names[query] then
        return true
    end

    local found
    for_each_matching(query, function(source)
        found = source
    end)

    return found ~= nil
end

M.register_name = function(name)
    registered.names[name] = true
end

M._reset = function()
    registered.sources = {}
    registered.names = {}
    registered.id = 0
end

M._set = function(sources)
    registered.sources = sources
end

return M
