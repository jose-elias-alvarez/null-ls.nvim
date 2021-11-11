local validate = vim.validate

local defaults = {
    diagnostics_format = "#{m}",
    debounce = 250,
    default_timeout = 5000,
    debug = false,
    -- private
    -- list of transformed sources
    _sources = {},
    -- list of names registered by integrations
    _names = {},
    -- prevent double setup
    _setup = false,
}

local config = vim.deepcopy(defaults)

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

local register_source = function(source)
    source = require("null-ls.sources").validate_and_transform(source)
    if not source then
        return
    end

    table.insert(config._sources, source)
    config._names[source.name] = true
    require("null-ls.lspconfig").on_register_source(source)
end

local register = function(to_register)
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
            source.filetypes = to_register.filetypes
            source.name = to_register.name

            register_source(source)
        end
    end

    require("null-ls.lspconfig").on_register_sources()
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

M.reset_sources = function()
    config._sources = {}
    config._names = {}
    require("null-ls.lspconfig").on_register_sources()
end

M.register = register

-- allow integrations to check if source is registered
M.is_registered = function(name)
    return config._names[name] ~= nil
end

-- allow integrations to register a name to quickly check if they've already registered
M.register_name = function(name)
    config._names[name] = true
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

    -- keep only transformed sources under private key
    config.sources = nil
    config._setup = true
end

return M
