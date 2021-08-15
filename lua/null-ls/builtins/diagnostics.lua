local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local M = {}

M.chktex = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "tex" },
    generator_opts = {
        command = "chktex",
        to_stdin = true,
        args = {
            -- Disable printing version information to stderr
            "-q",
            -- Format output
            "-f%l:%c:%d:%k:%m\n",
        },
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_pattern(
            [[(%d+):(%d+):(%d+):(%w+):(.+)]], --
            { "row", "col", "_length", "severity", "message" },
            {
                adapters = {
                    h.diagnostics.adapters.end_col.from_length,
                },
                severities = {
                    Error = h.diagnostics.severities["error"],
                    Warning = h.diagnostics.severities["warning"],
                },
            }
        ),
    },
    factory = h.generator_factory,
})

M.luacheck = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "lua" },
    generator_opts = {
        command = "luacheck",
        to_stdin = true,
        to_stderr = true,
        args = {
            "--formatter",
            "plain",
            "--codes",
            "--ranges",
            "--filename",
            "$FILENAME",
            "-",
        },
        format = "line",
        on_output = h.diagnostics.from_pattern(
            [[:(%d+):(%d+)-(%d+): %((%a)(%d+)%) (.*)]],
            { "row", "col", "end_col", "severity", "code", "message" },
            {
                adapters = {
                    h.diagnostics.adapters.end_col.from_quote,
                },
                severities = {
                    E = h.diagnostics.severities["error"],
                    W = h.diagnostics.severities["warning"],
                },
                offsets = { end_col = 1 },
            }
        ),
    },
    factory = h.generator_factory,
})

M.write_good = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "markdown" },
    generator_opts = {
        command = "write-good",
        args = { "--text=$TEXT", "--parse" },
        format = "line",
        check_exit_code = { 0, 255 },
        on_output = h.diagnostics.from_pattern(
            [[(%d+):(%d+):("([%w%s]+)".*)]], --
            { "row", "col", "message", "_quote" },
            {
                adapters = { h.diagnostics.adapters.end_col.from_quote },
                offsets = { col = 1, end_col = 1 },
            }
        ),
    },
    factory = h.generator_factory,
})

M.markdownlint = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "markdown" },
    generator_opts = {
        command = "markdownlint",
        args = { "--stdin" },
        to_stdin = true,
        to_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[:(%d+):(%d+) [%w-/]+ (.*)]],
                groups = { "row", "col", "message" },
            },
            {
                pattern = [[:(%d+) [%w-/]+ (.*)]],
                groups = { "row", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})

M.vale = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "markdown", "tex" },
    generator_opts = {
        command = "vale",
        format = "json",
        to_stdin = true,
        args = function(params)
            return { "--no-exit", "--output", "JSON", "--ext", "." .. vim.fn.fnamemodify(params.bufname, ":e") }
        end,
        on_output = function(params)
            local diagnostics = {}
            local severities = { error = 1, warning = 2, suggestion = 4 }
            for _, diagnostic in ipairs(params.output["stdin." .. vim.fn.fnamemodify(params.bufname, ":e")]) do
                table.insert(diagnostics, {
                    row = diagnostic.Line,
                    col = diagnostic.Span[1],
                    end_col = diagnostic.Span[2] + 1,
                    code = diagnostic.Check,
                    message = diagnostic.Message,
                    severity = severities[diagnostic.Severity],
                })
            end
            return diagnostics
        end,
    },
    factory = h.generator_factory,
})

M.teal = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "teal" },
    generator_opts = {
        command = "tl",
        args = { "check", "$FILENAME" },
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        to_stderr = true,
        to_temp_file = true,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[:(%d+):(%d+): (.* ['"]?([%w%.%-]+)['"]?)$]], --
                groups = { "row", "col", "message", "_quote" },
                overrides = {
                    adapters = { h.diagnostics.adapters.end_col.from_quote },
                    diagnostic = { source = "tl check" },
                },
            },
            {
                pattern = [[:(%d+):(%d+): (.*)]], --
                groups = { "row", "col", "message" },
                overrides = { diagnostic = { source = "tl check" } },
            },
        }),
    },
    factory = h.generator_factory,
})

M.shellcheck = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "sh" },
    generator_opts = {
        command = "shellcheck",
        args = { "--format", "json", "-" },
        to_stdin = true,
        format = "json",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_json({
            attributes = { code = "code" },
            severities = {
                info = h.diagnostics.severities["information"],
                style = h.diagnostics.severities["hint"],
            },
        }),
    },
    factory = h.generator_factory,
})

M.selene = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "lua" },
    generator_opts = {
        command = "selene",
        args = { "--display-style", "quiet", "-" },
        to_stdin = true,
        to_stderr = false,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_pattern(
            [[(%d+):(%d+): (%w+)%[([%w_]+)%]: ([`]*([%w_]+)[`]*.*)]],
            { "row", "col", "severity", "code", "message", "_quote" },
            { adapters = { h.diagnostics.adapters.end_col.from_quote }, offsets = { end_col = 1 } }
        ),
    },
    factory = h.generator_factory,
})

local handle_eslint_output = function(params)
    params.messages = params.output and params.output[1] and params.output[1].messages or {}
    if params.err then
        table.insert(params.messages, { message = params.err })
    end

    local parser = h.diagnostics.from_json({
        attributes = {
            severity = "severity",
        },
        severities = {
            h.diagnostics.severities["warning"],
            h.diagnostics.severities["error"],
        },
    })

    return parser({ output = params.messages })
end

M.eslint = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
    generator_opts = {
        command = "eslint",
        args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        format = "json_raw",
        check_exit_code = function(code)
            return code <= 1
        end,
        use_cache = true,
        on_output = handle_eslint_output,
    },
    factory = h.generator_factory,
})

M.eslint_d = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
    generator_opts = {
        command = "eslint_d",
        args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        format = "json_raw",
        check_exit_code = function(code)
            return code <= 1
        end,
        use_cache = true,
        on_output = handle_eslint_output,
    },
    factory = h.generator_factory,
})

M.hadolint = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "dockerfile" },
    generator_opts = {
        command = "hadolint",
        format = "json",
        args = { "--no-fail", "--format=json", "$FILENAME" },
        on_output = h.diagnostics.from_json({
            attributes = { code = "code" },
            severities = {
                info = h.diagnostics.severities["information"],
                style = h.diagnostics.severities["hint"],
            },
        }),
    },
    factory = h.generator_factory,
})

M.flake8 = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "flake8",
        to_stdin = true,
        to_stderr = true,
        args = { "--stdin-display-name", "$FILENAME", "-" },
        format = "line",
        check_exit_code = function(code)
            return code == 0 or code == 255
        end,
        on_output = h.diagnostics.from_pattern(
            [[:(%d+):(%d+): (([EFW])%w+) (.*)]], --
            { "row", "col", "code", "severity", "message" },
            {
                severities = {
                    E = h.diagnostics.severities["error"],
                    W = h.diagnostics.severities["warning"],
                    F = h.diagnostics.severities["information"],
                },
            }
        ),
    },
    factory = h.generator_factory,
})

M.pylint = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "pylint",
        to_stdin = true,
        to_stderr = false,
        args = { "--from-stdin", "$FILENAME", "-f", "json" },
        format = "json",
        check_exit_code = function(code)
            return not (code == 0 or code == 32)
        end,
        on_output = h.diagnostics.from_json({
            attributes = {
                row = "line",
                col = "column",
                code = "message-id",
                severity = "type",
                message = "message",
                source = "pylint",
            },
            severities = {
                convention = h.diagnostics.severities["information"],
                refactor = h.diagnostics.severities["information"],
            },
        }),
    },
    factory = h.generator_factory,
})

M.misspell = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "*" },
    generator_opts = {
        command = "misspell",
        to_stdin = true,
        format = "line",
        on_output = h.diagnostics.from_pattern(
            [[:(%d+):(%d+): (.*)]],
            { "row", "col", "message" },
            { diagnostic = { severity = h.diagnostics.severities["information"] }, offsets = { col = 1 } }
        ),
    },
    factory = h.generator_factory,
})

M.vint = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "vim" },
    generator_opts = {
        command = "vint",
        format = "json",
        args = { "--style-problem", "--json", "$FILENAME" },
        to_stdin = false,
        to_temp_file = true,
        check_exit_code = function(code)
            return code == 0 or code == 1
        end,
        on_output = h.diagnostics.from_json({
            attributes = {
                row = "line_number",
                col = "column_number",
                code = "policy_name",
                severity = "severity",
                message = "description",
            },
            severities = {
                style_problem = h.diagnostics.severities["information"],
            },
        }),
    },
    factory = h.generator_factory,
})

return M
