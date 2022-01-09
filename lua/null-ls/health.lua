local health = require("health")

local M = {}

local messages = {
    ["executable"] = [[%s: the command "%s" is executable.]],
    ["not-executable"] = [[%s: the command "%s" is not executable.]],
    ["unable"] = [[%s: cannot verify if the command is an executable.]],
    ["executable-local"] = [[%s: the command "%s" is not globally executable, but it may be available locally.]],
}

local function report(source)
    local name = source.name
    local only_local = source.generator.opts and source.generator.opts.only_local
    local command = source.generator.opts and source.generator.opts.command

    if type(command) ~= "string" then
        health.report_info(string.format(messages["unable"], name, command))
        return
    end

    if require("null-ls.utils").is_executable(command) then
        health.report_ok(string.format(messages["executable"], name, command))
        return
    end

    if only_local then
        health.report_warn(string.format(messages["executable-local"], name, command))
        return
    end

    health.report_error(string.format(messages["not-executable"], name, command))
end

M.check = function()
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
