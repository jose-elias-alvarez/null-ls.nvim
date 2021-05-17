local helpers = require("null-ls.helpers")
local u = require("null-ls.utils")

local api = vim.api

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

-- you probably don't want to use this - it's here for testing
M.toggle_line_comment = {
    fn = function(params)
        local bufnr = api.nvim_get_current_buf()
        local commentstring = api.nvim_buf_get_option(bufnr, "commentstring")
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
                    api.nvim_buf_set_lines(bufnr, params.row - 1, params.row,
                                           false,
                                           {string.format(commentstring, line)})
                end
            }
        }
    end
}

return M
