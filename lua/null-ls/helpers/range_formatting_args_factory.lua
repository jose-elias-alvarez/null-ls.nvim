local api = vim.api

return function(base_args, start_arg, end_arg)
    start_arg = start_arg or "--range-start"
    end_arg = end_arg or "--range-end"

    return function(params)
        local args = vim.deepcopy(base_args)
        if params.method == require("null-ls.methods").internal.FORMATTING then
            return args
        end

        local range = params.range

        local row, col = range.row - 1, range.col - 1
        local end_row, end_col = range.end_row - 1, range.end_col - 1

        -- neovim already takes care of offsets, so we can do this directly
        local range_start = api.nvim_buf_get_offset(params.bufnr, row) + col
        local range_end = api.nvim_buf_get_offset(params.bufnr, end_row) + end_col

        table.insert(args, start_arg)
        table.insert(args, range_start)
        table.insert(args, end_arg)
        table.insert(args, range_end)

        return args
    end
end
