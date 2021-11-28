local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

local shellcheck_disable_regex = vim.regex([[^\s*#\s*shellcheck\s\+disable=\(\(SC\)\?\d\+\)\(,\(SC\)\?\d\+\)*\s*$]])
local shellcheck_disable_pattern = "^%s*#%s*shellcheck%s+disable=([^%s]*)%s*$"

-- get_existing_disable gets a shellcheck disable string from linenr
-- linenr is 1-indexed
-- returns a string containing the disabled rules or nil
--
-- For example, given the following directive:
-- # shellcheck disable=SC1234,4321
--
-- get_existing_disable would return SC1234,4321
--
-- TODO: handle blank lines between code and line
local get_existing_disable = function(buf, linenr)
    local line = vim.api.nvim_buf_get_lines(buf, linenr - 1, linenr, false)[1]
    if not line or line == "" or not shellcheck_disable_regex:match_str(line) then
        return
    end
    return ({ line:match(shellcheck_disable_pattern) })[1]
end

local generate_edit_line_action = function(title, bufnr, opts)
    return {
        title = title,
        action = function()
            local res = type(opts) == "function" and opts() or opts
            vim.api.nvim_buf_set_lines(bufnr, res.first - 1, res.last - 1, false, { res.text })
        end,
    }
end

local generate_disable_actions = function(bufnr, code, row, indentation)
    local actions = {}

    local file_dest_line = 1
    if vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]:match("^#!") then
        -- Put the file disable comment after the shebang
        file_dest_line = 2
    end

    local file_title = "Disable ShellCheck rule SC" .. code .. " for the entire file"

    table.insert(
        actions,
        generate_edit_line_action(file_title, bufnr, function()
            local file_existing_disable = get_existing_disable(bufnr, file_dest_line)
            local file_codes = file_existing_disable and (file_existing_disable .. ",") or ""
            return {
                text = "# shellcheck disable=" .. file_codes .. code,
                first = file_dest_line,
                last = file_dest_line + (file_codes == "" and 0 or 1),
            }
        end)
    )

    local line_title = "Disable ShellCheck rule SC" .. code .. " for this line"

    table.insert(
        actions,
        generate_edit_line_action(line_title, bufnr, function()
            local line_existing_disable = get_existing_disable(bufnr, row - 1)
            local line_codes = line_existing_disable and (line_existing_disable .. ",") or ""
            return {
                text = indentation .. "# shellcheck disable=" .. line_codes .. code,
                first = row - (line_codes == "" and 0 or 1),
                last = row,
            }
        end)
    )

    return actions
end

local handler = function(params)
    local actions = {}

    local row = params.row
    local indentation = params.content[row]:match("^%s+") or ""

    for _, comment in ipairs(params.output.comments) do
        if row == comment.line then
            vim.list_extend(actions, generate_disable_actions(params.bufnr, comment.code, params.row, indentation))
        end
    end

    return actions
end

return h.make_builtin({
    method = CODE_ACTION,
    filetypes = { "sh" },
    generator_opts = {
        command = "shellcheck",
        args = { "--format", "json1", "--source-path=$DIRNAME", "--external-sources", "-" },
        to_stdin = true,
        format = "json",
        use_cache = true,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = handler,
    },
    factory = h.generator_factory,
})
