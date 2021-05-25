local helpers = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local api = vim.api

local M = {}
local write_good = {
    method = methods.internal.DIAGNOSTICS,
    filetypes = {"markdown"},
    generator = helpers.generator_factory(
        {
            command = "write-good",
            args = {"--text=$TEXT", "--parse"},
            format = "line",
            filetypes = {"markdown"},
            check_exit_code = function(code)
                return code == 0 or code == 255
            end,
            on_output = function(line, params)
                local pos = vim.split(string.match(line, "%d+:%d+"), ":")
                local row = pos[1]

                local message = string.match(line, ":([^:]+)$")

                local col, end_col
                local issue = string.match(line, "%b\"\"")
                local issue_line = params.content[tonumber(row)]
                if issue and issue_line then
                    local issue_start, issue_end =
                        string.find(issue_line, string.match(issue, "([^\"]+)"))
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
                    source = "write-good"
                }
            end
        })
}

M.markdown = {write_good = write_good}

-- testing
local toggle_line_comment = {
    method = methods.internal.CODE_ACTION,
    filetypes = {"*"},
    generator = {
        fn = function(params)
            local bufnr = api.nvim_get_current_buf()
            local commentstring =
                api.nvim_buf_get_option(bufnr, "commentstring")
            local raw_commentstring = u.string.replace(commentstring, "%s", "")
            local line = params.content[params.row]

            local has_comment = string.find(line, raw_commentstring, nil, true)
            if has_comment then
                return {
                    {
                        title = "Uncomment line",
                        action = function()
                            api.nvim_buf_set_lines(bufnr, params.row - 1,
                                                   params.row, false, {
                                u.string.replace(line, raw_commentstring, "")
                            })
                        end
                    }
                }
            end

            return {
                {
                    title = "Comment line",
                    action = function()
                        api.nvim_buf_set_lines(bufnr, params.row - 1,
                                               params.row, false, {
                            string.format(commentstring, line)
                        })
                    end
                }
            }
        end
    }
}

local mock_code_action = {
    method = methods.internal.CODE_ACTION,
    generator = {
        fn = function()
            return {
                {
                    title = "Mock action",
                    action = function()
                        print("I am a mock action!")
                    end
                }
            }
        end
    },
    filetypes = {"lua"}
}

local mock_diagnostics = {
    method = methods.internal.DIAGNOSTICS,
    generator = {
        fn = function()
            return {
                {
                    col = 1,
                    row = 1,
                    message = "There is something wrong with this file!",
                    severity = 1,
                    source = "mock-diagnostics"
                }
            }
        end
    },
    filetypes = {"markdown"}
}

M._test = {
    toggle_line_comment = toggle_line_comment,
    mock_code_action = mock_code_action,
    mock_diagnostics = mock_diagnostics
}

return M
