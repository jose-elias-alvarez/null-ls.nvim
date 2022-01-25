local u = require("null-ls.utils")

local validate = vim.validate

local defaults = {
    cmd = { "nvim" },
    debounce = 250,
    debug = false,
    default_timeout = 5000,
    diagnostics_format = "#{m}",
    fallback_severity = vim.diagnostic.severity.ERROR,
    ---@usage setting this to true will enable debug logging
    log = {
        ---@usage disable logging completely
        enable = true,
        ---@usage set logging level
        --- possible values: { "error", "warn", "info", "debug", "trace" }
        level = "warn",
        ---@usage whether to print the output to neovim's
        --- possible values: 'sync','async', false
        use_console = "async",
    },
    root_dir = u.root_pattern(".null-ls-root", "Makefile", ".git"),
    update_in_insert = false,
    -- prevent double setup
    _setup = false,
}

local config = vim.deepcopy(defaults)

local type_overrides = {
    on_attach = { "function", "nil" },
    on_init = { "function", "nil" },
    on_exit = { "function", "nil" },
    should_attach = { "function", "nil" },
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

local M = {}

M.get = function()
    return config
end

M._set = function(new_config)
    config = vim.tbl_extend("force", config, new_config)
end

M.reset = function()
    config = vim.deepcopy(defaults)
    require("null-ls.sources").reset()
end

M.setup = function(user_config)
    if config._setup then
        return
    end

    local validated = validate_config(user_config)
    config = vim.tbl_extend("force", config, validated)

    -- FIXME: validating log options should maintain any default options
    config.log = vim.tbl_extend("keep", config.log, defaults.log)

    if config.sources then
        require("null-ls.sources").register(config.sources)
    end

    config._setup = true
end

return M
