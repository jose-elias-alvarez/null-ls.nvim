local c = require("null-ls.config")
local u = require("null-ls.utils")

local default_notify_opts = {
    title = "null-ls",
}

local plenary_to_vim = {
    trace = vim.log.levels.TRACE,
    debug = vim.log.levels.DEBUG,
    info = vim.log.levels.INFO,
    warn = vim.log.levels.WARN,
    error = vim.log.levels.ERROR,
}

local log = {}

--- Adds a log entry using Plenary.log
---@param msg any
---@param level string [same as vim.log.log_levels]
function log:add_entry(msg, level)
    local cfg = c.get()

    if type(cfg.log) ~= "table" then
        return
    end

    if self.__handle then
        self.__handle(msg, level)
        return
    end

    local default_opts = {
        plugin = "null-ls",
        level = cfg.log.level or "warn",
        use_console = false,
        info_level = 4,
    }
    if cfg.debug then
        default_opts.use_console = false
        default_opts.level = "trace"
    end

    local has_plenary, plenary_log = pcall(require, "plenary.log")
    if not has_plenary then
        return
    end
    local plenary_logger = plenary_log.new(default_opts)

    local notify_level_max = plenary_to_vim[cfg.log.notify_level or "warn"] or -1
    self.__handle = function(m, l)
        plenary_logger[l](m)
        local notify_l = plenary_to_vim[l] or -1
        if notify_l >= notify_level_max then
            vim.notify(m, notify_l, default_notify_opts)
        end
    end

    self.__handle(msg, level)
end

---Retrieves the path of the logfile
---@return string path of the logfile
function log:get_path()
    return u.path.join(vim.fn.stdpath("cache"), "null-ls.log")
end

---Add a log entry at TRACE level
---@param msg any
function log:trace(msg)
    self:add_entry(msg, "trace")
end

---Add a log entry at DEBUG level
---@param msg any
function log:debug(msg)
    self:add_entry(msg, "debug")
end

---Add a log entry at INFO level
---@param msg any
function log:info(msg)
    self:add_entry(msg, "info")
end

---Add a log entry at WARN level
---@param msg any
function log:warn(msg)
    self:add_entry(msg, "warn")
end

---Add a log entry at ERROR level
---@param msg any
function log:error(msg)
    self:add_entry(msg, "error")
end

setmetatable({}, log)
return log
