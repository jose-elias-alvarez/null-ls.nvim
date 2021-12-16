-- adapted from Neovim's previous vim.lsp.util.compute_diff implementation
local M = {}

local function first_difference(old_lines, new_lines)
    local line_count = math.min(#old_lines, #new_lines)
    if line_count == 0 then
        return 1, 1
    end

    local start_line_idx
    for i = 1, line_count do
        start_line_idx = i
        if old_lines[start_line_idx] ~= new_lines[start_line_idx] then
            break
        end
    end

    local old_line = old_lines[start_line_idx]
    local new_line = new_lines[start_line_idx]
    local length = math.min(#old_line, #new_line)

    local start_col_idx = 1
    while start_col_idx <= length do
        if string.sub(old_line, start_col_idx, start_col_idx) ~= string.sub(new_line, start_col_idx, start_col_idx) then
            break
        end
        start_col_idx = start_col_idx + 1
    end

    return start_line_idx, start_col_idx
end

local function last_difference(old_lines, new_lines, start_char)
    local line_count = math.min(#old_lines, #new_lines)
    if line_count == 0 then
        return 0, 0
    end

    local end_line_idx = -1
    for i = end_line_idx, -line_count, -1 do
        if old_lines[#old_lines + i + 1] ~= new_lines[#new_lines + i + 1] then
            end_line_idx = i
            break
        end
    end

    local old_line
    local new_line
    if end_line_idx <= -line_count then
        end_line_idx = -line_count
        old_line = string.sub(old_lines[#old_lines + end_line_idx + 1], start_char)
        new_line = string.sub(new_lines[#new_lines + end_line_idx + 1], start_char)
    else
        old_line = old_lines[#old_lines + end_line_idx + 1]
        new_line = new_lines[#new_lines + end_line_idx + 1]
    end

    local old_line_length = #old_line
    local new_line_length = #new_line
    local length = math.min(old_line_length, new_line_length)
    local end_col_idx = -1
    while end_col_idx >= -length do
        local old_char = string.sub(old_line, old_line_length + end_col_idx + 1, old_line_length + end_col_idx + 1)
        local new_char = string.sub(new_line, new_line_length + end_col_idx + 1, new_line_length + end_col_idx + 1)
        if old_char ~= new_char then
            break
        end
        end_col_idx = end_col_idx - 1
    end

    return end_line_idx, end_col_idx
end

local function extract_text(lines, start_line, start_char, end_line, end_char, line_ending)
    if start_line == #lines + end_line + 1 then
        if end_line == 0 then
            return ""
        end

        local line = lines[start_line]
        local length = #line + end_char - start_char
        return string.sub(line, start_char, start_char + length + 1)
    end

    local result = string.sub(lines[start_line], start_char) .. line_ending
    for line_idx = start_line + 1, #lines + end_line do
        result = result .. lines[line_idx] .. line_ending
    end

    if end_line ~= 0 then
        local line = lines[#lines + end_line + 1]
        local length = #line + end_char + 1
        result = result .. string.sub(line, 1, length)
    end

    return result
end

local function compute_length(lines, start_line, start_char, end_line, end_char)
    local adj_end_line = #lines + end_line + 1

    local adj_end_char
    if adj_end_line > #lines then
        adj_end_char = end_char - 1
    else
        adj_end_char = #lines[adj_end_line] + end_char
    end

    if start_line == adj_end_line then
        return adj_end_char - start_char + 1
    end

    local result = #lines[start_line] - start_char + 1
    for line = start_line + 1, adj_end_line - 1 do
        result = result + #lines[line] + 1
    end
    result = result + adj_end_char + 1

    return result
end

function M.compute_diff(old_lines, new_lines, line_ending)
    line_ending = line_ending or "\n"

    local start_line, start_char = first_difference(old_lines, new_lines)
    local end_line, end_char = last_difference(
        vim.list_slice(old_lines, start_line, #old_lines),
        vim.list_slice(new_lines, start_line, #new_lines),
        start_char
    )
    local text = extract_text(new_lines, start_line, start_char, end_line, end_char, line_ending)
    local length = compute_length(old_lines, start_line, start_char, end_line, end_char)

    local adj_end_line = #old_lines + end_line
    local adj_end_char
    if end_line == 0 then
        adj_end_char = 0
    else
        adj_end_char = #old_lines[#old_lines + end_line + 1] + end_char + 1
    end

    local _, adjusted_start_char = vim.str_utfindex(old_lines[start_line], start_char - 1)
    local _, adjusted_end_char = vim.str_utfindex(old_lines[#old_lines + end_line + 1], adj_end_char)
    start_char = adjusted_start_char
    end_char = adjusted_end_char

    local result = {
        range = {
            start = { line = start_line - 1, character = start_char },
            ["end"] = { line = adj_end_line, character = end_char },
        },
        newText = text,
        rangeLength = length + 1,
    }

    return result
end

return M
