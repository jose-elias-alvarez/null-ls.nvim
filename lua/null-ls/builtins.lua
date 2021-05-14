local helpers = require("null-ls.helpers")

local M = {}
M.write_good = helpers.create_diagnostic_generator(
                   {
        command = "write-good",
        args = {"--text=$TEXT", "--parse"},
        format = "line",
        filetypes = {"markdown"},
        on_output = function(line, params)
            local pos = vim.split(string.match(line, "%d+:%d+"), ":")
            local row = pos[1]

            local message = string.match(line, ":([^:]+)$")

            local col, end_col
            local issue = string.match(line, "%b\"\"")
            if issue then
                local issue_start, issue_end =
                    string.find(params.content[tonumber(row)],
                                string.match(issue, "([^\"]+)"))
                col = tonumber(issue_start) - 1
                end_col = issue_end
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

return M
