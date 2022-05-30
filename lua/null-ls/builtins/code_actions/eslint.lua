local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local CODE_ACTION = methods.internal.CODE_ACTION

local api = vim.api

local get_offset_positions = function(content, start_offset, end_offset)
    -- ESLint uses character offsets, so convert to byte indexes to handle multibyte characters
    local to_string = table.concat(content, "\n")
    start_offset = vim.str_byteindex(to_string, start_offset + 1)
    end_offset = vim.str_byteindex(to_string, end_offset + 1)

    -- NOTE: These functions return 1-indexed lines
    local row = vim.fn.byte2line(start_offset)
    local end_row = vim.fn.byte2line(end_offset)

    local col = start_offset - vim.fn.line2byte(row)
    local end_col = end_offset - vim.fn.line2byte(end_row)
    return col + 1, row, end_col + 1, end_row
end

local is_fixable = function(problem, row)
    if not problem or not problem.line then
        return false
    end

    if problem.endLine then
        return problem.line <= row and problem.endLine >= row
    end

    if problem.fix then
        return problem.line - 1 == row
    end

    return false
end

local get_message_range = function(problem)
    -- 1-indexed
    local row = problem.line or 1
    local col = problem.column or 1
    local end_row = problem.endLine or 1
    local end_col = problem.endColumn or 1

    return { row = row, col = col, end_row = end_row, end_col = end_col }
end

local get_fix_range = function(problem, params)
    local offset = problem.fix.range[1]
    local end_offset = problem.fix.range[2]
    local col, row, end_col, end_row = get_offset_positions(params.content, offset, end_offset)

    return { row = row, col = col, end_row = end_row, end_col = end_col }
end

local generate_edit_action = function(title, new_text, range, params)
    return {
        title = title,
        action = function()
            -- 0-indexed
            api.nvim_buf_set_text(
                params.bufnr,
                range.row - 1,
                range.col - 1,
                range.end_row - 1,
                range.end_col - 1,
                vim.split(new_text, "\n")
            )
        end,
    }
end

local generate_edit_line_action = function(title, new_text, row, params)
    return {
        title = title,
        action = function()
            -- 0-indexed
            api.nvim_buf_set_lines(params.bufnr, row - 1, row - 1, false, { new_text })
        end,
    }
end

local generate_suggestion_action = function(suggestion, message, params)
    local title = suggestion.desc
    local new_text = suggestion.fix.text
    local range = get_message_range(message)

    return generate_edit_action(title, new_text, range, params)
end

local generate_fix_action = function(message, params)
    local title = "Apply suggested fix for ESLint rule " .. message.ruleId
    local new_text = message.fix.text
    local range = get_fix_range(message, params)

    return generate_edit_action(title, new_text, range, params)
end

local generate_disable_actions = function(message, indentation, params)
    local rule_id = message.ruleId

    local actions = {}
    local line_title = "Disable ESLint rule " .. rule_id .. " for this line"
    local line_new_text = indentation .. "// eslint-disable-next-line " .. rule_id
    table.insert(actions, generate_edit_line_action(line_title, line_new_text, message.line, params))

    local file_title = "Disable ESLint rule " .. rule_id .. " for the entire file"
    local file_new_text = "/* eslint-disable " .. rule_id .. " */"
    table.insert(actions, generate_edit_line_action(file_title, file_new_text, 1, params))

    return actions
end

local code_action_handler = function(params)
    local row = params.row
    local indentation = params.content[row]:match("^%s+") or ""

    local rules, actions = {}, {}
    for _, message in ipairs(params.messages) do
        if is_fixable(message, row) then
            if message.suggestions then
                for _, suggestion in ipairs(message.suggestions) do
                    table.insert(actions, generate_suggestion_action(suggestion, message, params))
                end
            end

            if message.fix then
                table.insert(actions, generate_fix_action(message, params))
            end

            if message.ruleId and not rules[message.ruleId] then
                rules[message.ruleId] = true
                vim.list_extend(actions, generate_disable_actions(message, indentation, params))
            end
        end
    end

    return actions
end

return h.make_builtin({
    name = "eslint",
    meta = {
        url = "https://github.com/eslint/eslint",
        description = "Injects actions to fix ESLint issues or ignore broken rules.",
    },
    method = CODE_ACTION,
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
    generator_opts = {
        command = "eslint",
        format = "json_raw",
        args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        check_exit_code = { 0, 1 },
        use_cache = true,
        on_output = function(params)
            local output = params.output

            if not (output and output[1] and output[1].messages) then
                return
            end

            params.messages = output[1].messages
            return code_action_handler(params)
        end,
        dynamic_command = cmd_resolver.from_node_modules,
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern(
                -- https://eslint.org/docs/user-guide/configuring/configuration-files#configuration-file-formats
                ".eslintrc",
                ".eslintrc.js",
                ".eslintrc.cjs",
                ".eslintrc.yaml",
                ".eslintrc.yml",
                ".eslintrc.json",
                "package.json"
            )(params.bufname)
        end),
    },
    factory = h.generator_factory,
})
