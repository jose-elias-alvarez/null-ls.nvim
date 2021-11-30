local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

local function range_formatting_args_factory(base_args, start_arg)
    vim.validate({
        base_args = { base_args, "table" },
        start_arg = { start_arg, "string" },
    })

    return function(params)
        local args = vim.deepcopy(base_args)
        if params.method == FORMATTING then
            return args
        end

        local range = params.range
        table.insert(args, start_arg)
        table.insert(args, range.row .. "-" .. range.end_row) -- range of lines to reformat, one-based
        return args
    end
end

return h.make_builtin({
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = { "python" },
    generator_opts = {
        command = "yapf",
        args = range_formatting_args_factory({
            "--quiet",
        }, "--lines"),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
