local health = vim.health

local error = health.error or health.report_error
local info = health.info or health.report_info
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn

local M = {}

local messages = {
    ["can-run"] = [[%s: the source "%s" can be ran.]],
    ["cannot-run"] = [[%s: the source "%s" cannot be ran.]],
    ["executable"] = [[%s: the command "%s" is executable.]],
    ["not-executable"] = [[%s: the command "%s" is not executable.]],
    ["unable"] = [[%s: cannot verify if the command is an executable.]],
    ["executable-local"] = [[%s: the command "%s" is not globally executable, but it may be available locally.]],
}

local function report(source)
    local name, can_run = source.name, source.can_run
    local opts = source.generator.opts or {}
    local command, only_local, prefer_local = opts.command, opts.only_local, opts.prefer_local

    if can_run then
        if can_run() then
            ok(string.format(messages["can-run"], name, name))
        else
            error(string.format(messages["cannot-run"], name, name))
        end
        return
    end

    if type(command) ~= "string" then
        info(string.format(messages["unable"], name, command))
        return
    end

    if require("null-ls.utils").is_executable(command) then
        ok(string.format(messages["executable"], name, command))
        return
    end

    if only_local or prefer_local then
        warn(string.format(messages["executable-local"], name, command))
        return
    end

    error(string.format(messages["not-executable"], name, command))
end

M.check = function()
    local registered_sources = require("null-ls.sources").get({})
    if #registered_sources == 0 then
        info("no sources registered")
        return
    end

    for _, source in ipairs(registered_sources) do
        report(source)
    end
end

return M
