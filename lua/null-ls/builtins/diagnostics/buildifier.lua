local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local function find_file_output(output, filename)
    if not output.files then
        return nil
    end
    for _, file in ipairs(output.files) do
        if file.filename == filename then
            return file
        end
    end
    return nil
end

local function parse_warnings(file_output)
    if not file_output.warnings then
        return {}
    end
    local diagnostics = {}
    for _, warning in ipairs(file_output.warnings) do
        if warning["start"] and warning["end"] then
            table.insert(diagnostics, {
                row = warning["start"]["line"],
                end_row = warning["end"]["line"],
                col = warning["start"]["column"],
                end_col = warning["end"]["column"],
                source = "buildifier",
                message = warning.message .. " (" .. warning.url .. ")",
                severity = h.diagnostics.severities["warning"],
            })
        end
    end
    return diagnostics
end

local function parse_error(line)
    local pattern = [[.-:(%d+):(%d+): (.*)]]
    local results = { line:match(pattern) }
    local row = tonumber(results[1])
    local col = tonumber(results[2])
    -- Remove trailing newline in the error message.
    local message = vim.trim(results[3])
    return {
        {
            row = row,
            col = col,
            source = "buildifier",
            message = message,
            severity = h.diagnostics.severities["error"],
        },
    }
end

return h.make_builtin({
    name = "buildifier",
    meta = {
        url = "https://github.com/bazelbuild/buildtools/tree/master/buildifier",
        description = "buildifier is a tool for formatting and linting bazel BUILD, WORKSPACE, and .bzl files.",
    },
    method = DIAGNOSTICS,
    filetypes = { "bzl" },
    generator_opts = {
        command = "buildifier",
        name = "buildifier",
        args = {
            "-mode=check",
            "-lint=warn",
            "-format=json",
            "-path=$FILENAME",
        },
        format = "json_raw",
        to_stdin = true,
        on_output = function(params)
            if params.err then
                return parse_error(params.err)
            end
            if not params.output then
                return {}
            end
            local file_output = find_file_output(params.output, params.bufname)
            if not file_output then
                return {}
            end
            return parse_warnings(file_output)
        end,
    },
    factory = h.generator_factory,
})
