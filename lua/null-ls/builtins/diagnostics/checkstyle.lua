local h = require("null-ls.helpers")

local function parse_checkstyle_errors(params, output)
    if params.err:match("Must specify a config XML file.") then
        table.insert(output, {
            message = "You need to specify a configuration for checkstyle."
                .. " See https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#checkstyle",
            severity = vim.diagnostic.severity.ERROR,
            bufnr = params.bufnr,
        })
        return
    end

    if params.err:match("Checkstyle ends with %d+ errors.") then
        return
    end

    table.insert(output, {
        message = vim.trim(params.err),
        severity = vim.diagnostic.severity.ERROR,
        bufnr = params.bufnr,
    })
end

local function handle_checkstyle_output(params)
    local output = {}

    if params.err then
        parse_checkstyle_errors(params, output)
    end

    local results = params.output and params.output.runs and params.output.runs[1] and params.output.runs[1].results
        or {}

    for _, result in ipairs(results) do
        for _, location in ipairs(result.locations) do
            local col = location.physicalLocation.region.startColumn

            table.insert(output, {
                row = location.physicalLocation.region.startLine,
                col = col,
                end_col = col and col + 1,
                code = result.ruleId,
                message = result.message.text,
                severity = h.diagnostics.severities[result.level],
                filename = location.physicalLocation.artifactLocation.uri,
            })
        end
    end

    return output
end

local function check_exit_code(code, stderr)
    return code == 0 or stderr:match("Checkstyle ends with " .. code .. " errors.")
end

return h.make_builtin({
    name = "checkstyle",
    meta = {
        url = "https://checkstyle.org",
        description = [[Checkstyle is a tool for checking Java source code for adherence to a Code Standard or set of
validation rules (best practices).]],
        usage = [[local sources = {
    null_ls.builtins.diagnostics.checkstyle.with({
        extra_args = { "-c", "/google_checks.xml" }, -- or "/sun_checks.xml" or path to self written rules
    }),
}]],
        notes = {
            [[Checkstyle only offers a jar file as download. It is recommended to put an executable wrapper script in
your path.
Example wrapper script:
```bash
#!/usr/bin/env bash
java -jar path/to/checkstyle.jar "$@"
```]],
            [[Checkstyle needs a mandatory `-c` argument. Use `extra_args` to add yours. `extra_args` can also be a
function to build more sophisticated logic.]],
        },
    },
    method = require("null-ls.methods").internal.DIAGNOSTICS_ON_SAVE,
    filetypes = { "java" },
    generator_opts = {
        args = { "-f", "sarif", "$ROOT" },
        check_exit_code = check_exit_code,
        command = "checkstyle",
        format = "json_raw",
        multiple_files = true,
        on_output = handle_checkstyle_output,
        to_stdin = false,
    },
    factory = h.generator_factory,
})
