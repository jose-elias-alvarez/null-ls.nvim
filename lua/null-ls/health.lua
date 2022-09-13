local health

local M = {}

local messages = {
    ["executable"] = [[%s: the command "%s" is executable.]],
    ["not-executable"] = [[%s: the command "%s" is not executable.]],
    ["unable"] = [[%s: cannot verify if the command is an executable.]],
    ["executable-local"] = [[%s: the command "%s" is not globally executable, but it may be available locally.]],
}

local function report(source)
    local name = source.name
    local opts = source.generator.opts or {}
    local command, only_local, prefer_local = opts.command, opts.only_local, opts.prefer_local

    if type(command) ~= "string" then
        health.report_info(string.format(messages["unable"], name, command))
        return
    end

    if require("null-ls.utils").is_executable(command) then
        health.report_ok(string.format(messages["executable"], name, command))
        return
    end

    if only_local or prefer_local then
        health.report_warn(string.format(messages["executable-local"], name, command))
        return
    end

    health.report_error(string.format(messages["not-executable"], name, command))
end

M.check = function()
    if not health then
        health = require("null-ls.utils").has_version("0.8") and vim.health or require("health")
    end

    local registered_sources = require("null-ls.sources").get({})
    if #registered_sources == 0 then
        health.report_info("no sources registered")
        return
    end

    for _, source in ipairs(registered_sources) do
        report(source)
    end
end

return M
