local stub = require("luassert.stub")
local methods = require("null-ls.methods")

describe("range_formatting_args_factory", function()
    local factory = require("null-ls.helpers").range_formatting_args_factory
    local base_args = { "--quiet" }
    local start_arg = "--range-start"
    local end_arg = "--range-end"

    local mock_bufnr = 15
    local mock_range = { row = 1, col = 1, end_row = 5, end_col = 5 }
    local get_offset = stub(vim.api, "nvim_buf_get_offset")
    local mock_offset = 100
    before_each(function()
        get_offset.returns(mock_offset)
    end)
    after_each(function()
        get_offset:clear()
    end)

    it("should return base args when method is FORMATTING", function()
        local args_fn = factory(base_args, start_arg, end_arg)

        local resolved_args = args_fn({ method = methods.internal.FORMATTING })

        assert.same(resolved_args, base_args)
    end)

    it("should extend args when method is RANGE_FORMATTING", function()
        local args_fn = factory(base_args, start_arg, end_arg)

        local resolved_args = args_fn({
            method = methods.internal.RANGE_FORMATTING,
            range = mock_range,
            bufnr = mock_bufnr,
        })

        assert.stub(get_offset).was_called_with(mock_bufnr, mock_range.row)
        assert.same(
            resolved_args,
            vim.list_extend(base_args, {
                start_arg,
                mock_offset + mock_range.col,
                end_arg,
                mock_offset + mock_range.end_col,
            })
        )
    end)

    it("should skip end arg when not specified", function()
        local args_fn = factory(base_args, start_arg, nil)

        local resolved_args = args_fn({
            method = methods.internal.RANGE_FORMATTING,
            range = mock_range,
            bufnr = mock_bufnr,
        })

        assert.stub(get_offset).was_called_with(mock_bufnr, mock_range.row)
        assert.same(
            resolved_args,
            vim.list_extend(base_args, {
                start_arg,
                mock_offset + mock_range.col,
                mock_offset + mock_range.end_col,
            })
        )
    end)

    it("should apply row offset", function()
        local opts = { row_offset = 10 }
        local args_fn = factory(base_args, start_arg, end_arg, opts)

        local resolved_args = args_fn({
            method = methods.internal.RANGE_FORMATTING,
            range = mock_range,
            bufnr = mock_bufnr,
        })

        assert.stub(get_offset).was_called_with(mock_bufnr, mock_range.row + opts.row_offset)
        assert.same(
            resolved_args,
            vim.list_extend(base_args, {
                start_arg,
                mock_offset + mock_range.col,
                end_arg,
                mock_offset + mock_range.end_col,
            })
        )
    end)

    it("should apply col offset", function()
        local opts = { col_offset = 10 }
        local args_fn = factory(base_args, start_arg, end_arg, opts)

        local resolved_args = args_fn({
            method = methods.internal.RANGE_FORMATTING,
            range = mock_range,
            bufnr = mock_bufnr,
        })

        assert.same(
            resolved_args,
            vim.list_extend(base_args, {
                start_arg,
                mock_offset + mock_range.col + opts.col_offset,
                end_arg,
                mock_offset + mock_range.end_col + opts.col_offset,
            })
        )
    end)

    it("should use rows", function()
        local opts = { use_rows = true }
        local args_fn = factory(base_args, start_arg, end_arg, opts)

        local resolved_args = args_fn({
            method = methods.internal.RANGE_FORMATTING,
            range = mock_range,
            bufnr = mock_bufnr,
        })

        assert.same(
            resolved_args,
            vim.list_extend(base_args, {
                start_arg,
                mock_range.row,
                end_arg,
                mock_range.end_row,
            })
        )
    end)

    it("should use length instead of end of range position", function()
        local opts = { use_length = true }
        local args_fn = factory(base_args, start_arg, end_arg, opts)

        local resolved_args = args_fn({
            method = methods.internal.RANGE_FORMATTING,
            range = mock_range,
            bufnr = mock_bufnr,
        })

        assert.same(
            resolved_args,
            vim.list_extend(base_args, {
                start_arg,
                mock_offset + mock_range.col,
                end_arg,
                mock_range.end_col - mock_range.col,
            })
        )
    end)

    it("should join range with delimiter", function()
        local opts = { delimiter = "-" }
        local args_fn = factory(base_args, start_arg, nil, opts)

        local resolved_args = args_fn({
            method = methods.internal.RANGE_FORMATTING,
            range = mock_range,
            bufnr = mock_bufnr,
        })

        assert.same(
            resolved_args,
            vim.list_extend(base_args, {
                start_arg,
                mock_offset + mock_range.col .. opts.delimiter .. mock_offset + mock_range.end_col,
            })
        )
    end)
end)
