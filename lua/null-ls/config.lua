local validate = vim.validate

local defaults = {
    debounce = 250,
    on_attach = nil,
    generators = {},
    filetypes = {}
}

local config = vim.deepcopy(defaults)

local register_filetypes = function(filetypes)
    for _, filetype in pairs(filetypes) do
        if not vim.tbl_contains(config.filetypes, filetype) then
            table.insert(config.filetypes, filetype)
        end
    end
end

local register_source = function(source)
    local method, generators, filetypes = source.method, source.generators,
                                          source.filetypes
    validate({
        method = {method, "string"},
        generators = {generators, "table"},
        filetypes = {filetypes, "table"}
    })

    if not config.generators[method] then config.generators[method] = {} end
    register_filetypes(filetypes)

    for _, generator in ipairs(generators) do
        generator.filetypes = filetypes
        table.insert(config.generators[method], generator)
    end
end

local register_sources = function(sources)
    for _, source in ipairs(sources) do register_source(source) end
end

local M = {}

M.get = function() return config end

M.reset = function() config = vim.deepcopy(defaults) end

M.register_source = register_source
M.register_sources = register_sources
M.reset_sources = function() config.generators = {} end

M.generators = function(method)
    if method then return config.generators[method] end
    return config.generators
end

M.setup = function(user_config)
    local on_attach, debounce, user_sources = user_config.on_attach,
                                              user_config.debounce,
                                              user_config.sources

    validate({
        on_attach = {on_attach, "function", true},
        debounce = {debounce, "number", true},
        sources = {user_sources, "table", true}
    })

    if on_attach then config.on_attach = on_attach end
    if debounce then config.debounce = debounce end
    if user_sources then register_sources(user_sources) end
end

return M
