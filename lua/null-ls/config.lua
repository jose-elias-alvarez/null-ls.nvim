local methods = require("null-ls.methods")

local validate = vim.validate

local defaults = {
    diagnostics_format = "#{m}",
    debounce = 250,
    default_timeout = 5000,
    debug = false,
    _generators = {},
    _filetypes = {},
    _all_filetypes = false,
    _names = {},
    _methods = {},
    _registered = false,
    _setup = false,
}

local type_overrides = {
    on_attach = { "function", "nil" },
    sources = { "table", "nil" },
}

local wanted_type = function(k)
    if vim.startswith(k, "_") then
        return "nil", true
    end

    local override = type_overrides[k]
    if type(override) == "string" then
        return override, true
    end
    if type(override) == "table" then
        return function(a)
            return vim.tbl_contains(override, type(a))
        end,
            table.concat(override, ", ")
    end

    return type(defaults[k]), true
end

local config = vim.deepcopy(defaults)

local register_filetypes = function(filetypes)
    if
        vim.tbl_isempty(filetypes) -- empty list
        or not vim.tbl_islist(filetypes) -- disabled filetypes, e.g. { lua = false }
    then
        config._all_filetypes = true
        return
    end

    for _, filetype in pairs(filetypes) do
        if not vim.tbl_contains(config._filetypes, filetype) then
            table.insert(config._filetypes, filetype)
        end
    end
    require("null-ls.lspconfig").on_register_filetypes()
end

local should_register = function(source, filetypes, source_methods)
    local name = source.name
    -- can't do anything without a name
    if not source.name then
        return true
    end

    for _, method in ipairs(source_methods) do
        config._methods[method] = config._methods[method] or {}
        if config._methods[method][name] and not source._is_copy then
            return false
        end

        config._methods[method][name] = vim.tbl_islist(filetypes)
                and vim.list_extend(config._methods[method][name] or {}, filetypes)
            or vim.tbl_extend("force", config._methods[method][name] or {}, filetypes)
    end

    return true
end

local register_source = function(source, filetypes)
    if type(source) == "function" then
        source = source()
        if not source then
            return
        end
    end

    local generator, name = source.generator, source.name
    local source_methods = type(source.method) == "table" and source.method or { source.method }
    filetypes = filetypes or source.filetypes

    validate({
        generator = { generator, "table" },
        filetypes = { filetypes, "table" },
        name = { name, "string", true },
    })

    if not should_register(source, filetypes, source_methods) then
        return
    end

    for _, method in pairs(source_methods) do
        validate({
            method = {
                method,
                function(m)
                    return methods.internal[m] ~= nil
                end,
                "supported null-ls method",
            },
        })

        local fn, async, opts = generator.fn, generator.async, generator.opts
        validate({
            fn = { fn, "function" },
            async = { async, "boolean", true },
            opts = { opts, "table", true },
        })

        if not config._generators[method] then
            config._generators[method] = {}
        end
        register_filetypes(filetypes)

        generator.filetypes = filetypes
        generator.opts = opts or {}
        table.insert(config._generators[method], generator)
    end

    config._registered = true
    require("null-ls.lspconfig").on_register_source(source_methods)
end

-- allow integrations to check if source is registered
local is_registered = function(name)
    return config._names[name] ~= nil
end

local register = function(to_register)
    -- register a single source
    if type(to_register) == "function" or (type(to_register) == "table" and to_register.method) then
        register_source(to_register)
        return
    end

    -- register a simple list of sources
    if not to_register.sources then
        for _, source in pairs(to_register) do
            register_source(source)
        end
        return
    end

    -- register multiple sources with shared configuration
    local sources, filetypes, name = to_register.sources, to_register.filetypes, to_register.name
    validate({ sources = { sources, "table" }, name = { name, "string", true } })

    if name then
        if is_registered(name) then
            return
        end
        config._names[name] = true
    end

    for _, source in pairs(sources) do
        register_source(source, filetypes)
    end
end

local M = {}

M.get = function()
    return config
end
M._set = function(new_config)
    config = vim.tbl_extend("force", config, new_config)
end
M.reset = function()
    config = vim.deepcopy(defaults)
end

M.is_registered = is_registered
M.register_name = function(name)
    config._names[name] = true
end

M.register = register

M.reset_sources = function()
    config._generators = {}
    config._names = {}
    config._methods = {}
    config._filetypes = {}
end

local validate_config = function(user_config)
    local to_validate, validated = {}, {}

    local get_wanted = function(config_table)
        for k in pairs(config_table) do
            local wanted, optional = wanted_type(k)
            to_validate[k] = { user_config[k], wanted, optional }

            validated[k] = user_config[k]
        end
    end
    get_wanted(config)
    get_wanted(type_overrides)

    validate(to_validate)
    return validated
end

M.setup = function(user_config)
    if config._setup then
        return
    end

    local validated = validate_config(user_config)
    config = vim.tbl_extend("force", config, validated)

    if config.sources then
        register(config.sources)
    end

    config._setup = true
end

return M
