local h = require("null-ls.helpers")

local function parse_pmd_error(params, line, output)
    if line:match("net%.sourceforge%.pmd") or line:match("Run with %-%-help for command line help%.") then
        return
    end

    if vim.regex("\\vAnalysis cache (loaded|invalidated|updated)"):match_str(line) then
        return
    end

    if line:match("The following option is required: %-%-rulesets") then
        table.insert(output, {
            message = "You need to specify a ruleset for PMD."
                .. " See https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#pmd",
            severity = vim.diagnostic.severity.ERROR,
            bufnr = params.bufnr,
        })
        return
    end

    local severity = vim.diagnostic.severity.ERROR
    if vim.regex("^WARNING:"):match_str(line) then
        severity = vim.diagnostic.severity.WARN
    elseif vim.regex("^INFO:"):match_str(line) then
        severity = vim.diagnostic.severity.INFO
    end

    local message = line
    if vim.regex("\\v^\\w+: "):match_str(line) then
        message = line:sub(line:find(":") + 2)
    end

    table.insert(output, {
        code = "stderr",
        message = vim.trim(message),
        severity = severity,
        bufnr = params.bufnr,
    })
end

local function parse_pmd_errors(params, output)
    local lines = vim.split(params.err, "\n", { trimempty = true })
    for _, line in ipairs(lines) do
        parse_pmd_error(params, line, output)
    end
end

local function handle_pmd_output(params)
    local output = {}

    local files = params.output and params.output.files or {}

    if params.err then
        parse_pmd_errors(params, output)
    end

    for _, file in ipairs(files) do
        for _, violation in ipairs(file.violations) do
            table.insert(output, {
                row = violation.beginline,
                col = violation.begincolumn,
                end_row = violation.endline,
                end_col = violation.endcolumn and violation.endcolumn + 1,
                code = violation.ruleset .. "/" .. violation.rule,
                message = violation.description,
                severity = violation.priority and math.max(1, violation.priority - 1),
                filename = file.filename,
            })
        end
    end

    return output
end

return h.make_builtin({
    name = "pmd",
    meta = {
        url = "https://pmd.github.io",
        description = "An extensible cross-language static code analyzer.",
        usage = [[local sources = {
    null_ls.builtins.diagnostics.pmd.with({
        extra_args = {
            "--rulesets",
            "category/java/bestpractices.xml,category/jsp/bestpractices.xml" -- or path to self-written ruleset
        },
    }),
}]],
        notes = {
            [[PMD only offers parameterized wrapper scripts as download. It is recommended to put an executable wrapper
script in your path.
Example wrapper script:
```bash
#!/usr/bin/env bash
path/to/pmd/bin/run.sh pmd "$@"
```]],
            [[PMD needs a mandatory `--rulesets`/`-rulesets`/`-R` argument. Use `extra_args` to add yours. `extra_args`
can also be a function to build more sophisticated logic.]],
        },
    },
    method = require("null-ls.methods").internal.DIAGNOSTICS_ON_SAVE,
    filetypes = { "java", "jsp" },
    generator_opts = {
        args = { "--format", "json", "--dir", "$ROOT" },
        check_exit_code = { 0, 4 },
        command = "pmd",
        format = "json_raw",
        multiple_files = true,
        on_output = handle_pmd_output,
        to_stdin = false,
    },
    factory = h.generator_factory,
})
