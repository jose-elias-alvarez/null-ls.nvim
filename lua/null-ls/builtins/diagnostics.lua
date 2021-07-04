local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local M = {}

M.write_good = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "markdown" },
    generator_opts = {
        command = "write-good",
        args = { "--text=$TEXT", "--parse" },
        format = "line",
        check_exit_code = function(code)
            return code == 0 or code == 255
        end,
        on_output = function(line, params)
            local pos = vim.split(string.match(line, "%d+:%d+"), ":")
            local row = pos[1]

            local message = string.match(line, ":([^:]+)$")

            local col, end_col
            local issue = string.match(line, '%b""')
            local issue_line = params.content[tonumber(row)]
            if issue and issue_line then
                local issue_start, issue_end = string.find(issue_line, string.match(issue, '([^"]+)'))
                if issue_start and issue_end then
                    col = tonumber(issue_start) - 1
                    end_col = issue_end
                end
            end

            return {
                row = row,
                col = col,
                end_col = end_col,
                message = message,
                severity = 1,
                source = "write-good",
            }
        end,
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
        on_output = function(line, params)
            local split = vim.split(line, " ")
            local rule = split[2]
            local _, rule_end = string.find(line, rule, nil, true)
            local message = string.sub(line, rule_end + 2)

            local pos = vim.split(split[1], ":")
            local row = pos[2]
            local col = pos[3]

            local end_col
            local issue = string.match(line, "%b[]")
            if issue then
                issue = string.sub(issue, 2, #issue - 1)
                local issue_line = params.content[tonumber(row)]
                _, end_col = string.find(issue_line, issue, nil, true)
            end

            return {
                row = row,
                col = col and col - 1,
                end_col = end_col,
                message = message,
                severity = 1,
                source = "markdownlint",
            }
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
        check_exit_code = function(code)
            return code <= 1
        end,
        to_stderr = true,
        to_temp_file = true,
        on_output = function(params, done)
            if not params.output or params.output == "" then
                return done()
            end

            local diagnostics, severity = {}, nil
            for _, line in ipairs(vim.split(params.output, "\n")) do
                if not string.find(line, "^===") then
                    if string.find(line, "warning") then
                        severity = 2
                    end
                    if string.find(line, "error") then
                        severity = 1
                    end
                    if string.find(line, "/tmp/", nil) then
                        local split = vim.split(line, " ")

                        local pos = vim.split(split[1], ":")
                        local row = pos[2]
                        local col = pos[3]
                        if row and col then
                            local _, message_start = string.find(line, split[1], nil, true)
                            local message = string.sub(line, message_start + 2)

                            local content_line = params.content[tonumber(row)]
                            local end_col = col
                            for i = col, #content_line do
                                i = i + 1
                                local next_char = string.sub(content_line, i, i)
                                if next_char == "" or string.find(next_char, "[^%w\"'.:]") then
                                    break
                                end
                                end_col = i
                            end

                            table.insert(diagnostics, {
                                row = row,
                                col = col - 1,
                                end_col = end_col,
                                message = message,
                                severity = severity,
                                source = "tl check",
                            })
                        end
                    end
                end
            end

            return done(diagnostics)
        end,
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
        on_output = function(params)
            local diagnostics = {}
            for _, diagnostic in ipairs(params.output) do
                table.insert(diagnostics, {
                    row = diagnostic.line,
                    col = diagnostic.column - 1,
                    end_row = diagnostic.endLine,
                    end_col = diagnostic.endColumn == diagnostic.column and diagnostic.endColumn
                        or diagnostic.endColumn - 1,
                    message = diagnostic.message,
                    source = "shellcheck",
                    severity = diagnostic.level == "error" and 1
                        or diagnostic.level == "warning" and 2
                        or diagnostic.level == "info" and 3
                        or diagnostic.level == "style" and 4,
                })
            end
            return diagnostics
        end,
    },
    factory = h.generator_factory,
})

M.eslint = h.make_builtin({
    method = DIAGNOSTICS,
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    generator_opts = {
        command = "eslint",
        args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        format = "json_raw",
        check_exit_code = function(code)
            return code <= 1
        end,
        use_cache = true,
        on_output = function(params)
            local get_message_range = function(problem)
                local row = problem.line and problem.line > 0 and problem.line - 1 or 0
                local col = problem.column and problem.column > 0 and problem.column - 1 or 0
                local end_row = problem.endLine and problem.endLine - 1 or 0
                local end_col = problem.endColumn and problem.endColumn - 1 or 0
                return { row = row, col = col, end_row = end_row, end_col = end_col }
            end

            local create_diagnostic = function(message)
                local range = get_message_range(message)
                return {
                    message = message.message,
                    code = message.ruleId,
                    row = range.row + 1,
                    col = range.col,
                    end_row = range.end_row + 1,
                    end_col = range.end_col,
                    severity = message.severity == 1 and 2 or 1,
                    source = "eslint",
                }
            end

            local diagnostics = {}
            params.messages = params.output and params.output[1] and params.output[1].messages or {}
            if params.err then
                table.insert(params.messages, { message = params.err })
            end

            for _, message in ipairs(params.output[1].messages) do
                table.insert(diagnostics, create_diagnostic(message))
            end
            return diagnostics
        end,
    },
    factory = h.generator_factory,
})

return M
