local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local build_offense = function(record, line)
    return {
        message = record.smell_type .. ": " .. record.message,
        smell_type = record.smell_type,
        severity = h.diagnostics.severities.warning,
        row = line,
        col = 0,
        end_col = 1,
        filename = record.source,
    }
end

local handle_record = function(record, offenses)
    for _, line in ipairs(record.lines) do
        table.insert(offenses, build_offense(record, line))
    end
end

local handle_output = function(params)
    local offenses = {}

    if params.output then
        for _, record in ipairs(params.output) do
            handle_record(record, offenses)
        end
    end

    return offenses
end

return h.make_builtin({
    name = "reek",

    meta = {
        url = "https://github.com/troessner/reek",
        description = "Code smell detector for Ruby",
    },

    method = DIAGNOSTICS,
    filetypes = { "ruby" },
    generator_opts = {
        command = "reek",
        args = { "--format", "json", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        from_stderr = true,
        format = "json",

        check_exit_code = function(code)
            return code <= 1
        end,

        on_output = handle_output,
    },
    factory = h.generator_factory,
})
