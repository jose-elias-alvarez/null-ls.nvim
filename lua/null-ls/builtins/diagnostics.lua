local methods = require("null-ls.methods")
local helpers = require("null-ls.helpers")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local M = {}

M.write_good = {
    method = DIAGNOSTICS,
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

return M
