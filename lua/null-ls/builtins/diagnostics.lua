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

return M
