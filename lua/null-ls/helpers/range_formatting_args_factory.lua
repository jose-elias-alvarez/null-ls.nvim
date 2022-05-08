local api = vim.api

---@class RangeFormattingArgsFactoryOpts
---@field row_offset? number offset applied to row numbers
---@field col_offset? number offset applied to column numbers
---@field use_rows? boolean use rows over char offsets
---@field use_length? boolean use length of range in end_arg instead of end position
---@field delimiter? string used to join ranges

--- creates a function that returns arguments depending on formatting method
---@param base_args string[] base arguments required to run formatter
---@param start_arg string name of argument that marks start of range
---@param end_arg string? name of argument that marks end of range
---@param opts RangeFormattingArgsFactoryOpts table of options
---@return fun(params: NullLsParams): string[]
local range_formatting_args_factory = function(base_args, start_arg, end_arg, opts)
    vim.validate({
        base_args = { base_args, "table" },
        start_arg = { start_arg, "string" },
        end_arg = { end_arg, "string", true },
        opts = { opts, "table", true },
    })
    opts = opts or {}

    ---@param params NullLsParams
    return function(params)
        local args = vim.deepcopy(base_args)
        if params.method == require("null-ls.methods").internal.FORMATTING then
            return args
        end

        local range = params.range
        local row, col, end_row, end_col = range.row, range.col, range.end_row, range.end_col
        if opts.row_offset then
            row = row + opts.row_offset
            end_row = end_row + opts.row_offset
        end
        if opts.col_offset then
            col = col + opts.col_offset
            end_col = end_col + opts.col_offset
        end

        -- neovim already takes care of offsets when generating the range
        local range_start = opts.use_rows and row or api.nvim_buf_get_offset(params.bufnr, row) + col
        local range_end = opts.use_rows and end_row or api.nvim_buf_get_offset(params.bufnr, end_row) + end_col

        if opts.use_length then
            range_end = range_end - range_start
        end

        table.insert(args, start_arg)

        if opts.delimiter then
            local joined_range = range_start .. opts.delimiter .. range_end
            table.insert(args, joined_range)
        else
            table.insert(args, range_start)
            if end_arg then
                table.insert(args, end_arg)
            end
            table.insert(args, range_end)
        end

        return args
    end
end

return range_formatting_args_factory
