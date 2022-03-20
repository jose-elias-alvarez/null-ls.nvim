local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

local blank_or_comment_line_regex = vim.regex([[^\s*\(#.*\)\?$]])
local shebang_regex = vim.regex([[^#!]])
local multiline_command_regex = vim.regex([[^.*\\$]])
local shellcheck_disable_regex = vim.regex([[^\s*#\s*shellcheck\s\+disable=\(\(SC\)\?\d\+\)\([,-]\(SC\)\?\d\+\)*\s*$]])
local shellcheck_disable_pattern = "^%s*#%s*shellcheck%s+disable=([^%s]*)%s*$"

-- Searches a region of the buffer `bufnr` for `regex`, returning the first match.
-- The search proceeds from `row_start` to `row_end`.
--
-- If `row_start` is greater than `row_end`, the region is effectively searched in reverse.
--
-- If `regex` doesn't match a line and `continue_regex` is not nil, the line is
-- tested against `continue_regex`; if the line doesn't match, the search halts.
--
-- The first return value is the matching line and the second return value is
-- the line number.
-- nil is returned for no match.
local search_region = function(bufnr, regex, row_start, row_end, continue_regex, invert)
    invert = invert ~= nil and invert or false
    local region_start, region_end
    local idx_start, idx_end, step
    if row_start > row_end then
        region_start = row_end
        region_end = row_start
        idx_start = row_start - row_end
        idx_end = 1
        step = -1
    else
        region_start = row_start
        region_end = row_end
        idx_start = 1
        idx_end = row_end - row_start
        step = 1
    end
    local lines = vim.api.nvim_buf_get_lines(bufnr, region_start, region_end, false)
    for i = idx_start, idx_end, step do
        local line = lines[i]
        if line == nil then
            return
        end
        local match = regex:match_str(line) ~= nil
        if match == not invert then
            return line, i + (step == 1 and row_start or row_end)
        end
        if continue_regex and not continue_regex:match_str(line) then
            return
        end
    end
end

local get_first_non_shebang_row = function(bufnr)
    return shebang_regex:match_line(bufnr, 0) and 1 or 0
end

local get_first_non_comment_row = function(bufnr, row)
    local first_non_shebang_row = get_first_non_shebang_row(bufnr)
    local _, match_row = search_region(bufnr, blank_or_comment_line_regex, first_non_shebang_row, row, nil, true)
    return match_row
end

local find_disable_directive = function(bufnr, row_start, row_end)
    local line, row = search_region(bufnr, shellcheck_disable_regex, row_start, row_end, blank_or_comment_line_regex)
    return line and {
        codes = line:match(shellcheck_disable_pattern),
        row = row,
    } or nil
end

local get_file_directive = function(bufnr)
    local row_start = get_first_non_shebang_row(bufnr)
    local row_end = vim.api.nvim_buf_line_count(bufnr)
    return find_disable_directive(bufnr, row_start, row_end)
end

local get_line_directive = function(bufnr, row)
    local file_directive = get_file_directive(bufnr)
    local row_start = row - 1
    local row_end = file_directive and file_directive.row or get_first_non_shebang_row(bufnr)
    return find_disable_directive(bufnr, row_start, row_end)
end

local disable_action = function(bufnr, existing_directive, default_line, code, indentation)
    local codes = code
    local row_start = default_line - 1
    local row_end = default_line - 1
    if existing_directive then
        codes = existing_directive.codes .. "," .. codes
        row_start = existing_directive.row - 1
        row_end = existing_directive.row
    end
    local directive = indentation .. "# shellcheck disable=" .. codes
    vim.api.nvim_buf_set_lines(bufnr, row_start, row_end, false, { directive })
end

local generate_file_disable_action = function(bufnr, code)
    return {
        title = "Disable ShellCheck rule " .. code .. " for the entire file",
        action = function()
            return disable_action(bufnr, get_file_directive(bufnr), get_first_non_shebang_row(bufnr) + 1, code, "")
        end,
    }
end

local generate_line_disable_action = function(bufnr, row, code, indentation)
    if get_first_non_comment_row(bufnr, row) == row then
        return
    end
    local _, match_row = search_region(bufnr, multiline_command_regex, row - 1, 0, nil, true)
    row = match_row + 1
    indentation = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]:match("^%s+") or ""
    return {
        title = "Disable ShellCheck rule " .. code .. " for this line",
        action = function()
            return disable_action(bufnr, get_line_directive(bufnr, row), row, code, indentation)
        end,
    }
end

local generate_disable_actions = function(bufnr, code, row, indentation)
    return {
        generate_file_disable_action(bufnr, code),
        generate_line_disable_action(bufnr, row, code, indentation),
    }
end

local code_action_handler = function(params)
    if not (params.output and params.output.comments) then
        return
    end
    local actions = {}
    local indentation = params.content[params.row]:match("^%s+") or ""
    for _, comment in ipairs(params.output.comments) do
        if params.row == comment.line then
            vim.list_extend(actions, generate_disable_actions(params.bufnr, comment.code, params.row, indentation))
        end
    end
    return actions
end

return h.make_builtin({
    name = "shellcheck",
    meta = {
        url = "https://www.shellcheck.net/",
        description = "Provides actions to disable ShellCheck errors/warnings, either for the current line or for the entire file.",
        notes = {
            "Running the action to disable a rule for the current line adds a disable directive above the line or appends the rule to an existing disable directive for that line.",
            "Running the action to disable a rule for the current file adds a disable directive at the top of the file or appends the rule to an existing file disable directive.",
            "The first non-comment line in a script is not eligible for a line-level disable directive. See [shellcheck#1877](https://github.com/koalaman/shellcheck/issues/1877).",
        },
    },
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
        on_output = code_action_handler,
    },
    factory = h.generator_factory,
})
