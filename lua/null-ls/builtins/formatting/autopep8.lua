local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

local function range_formatting_args_factory(base_args, start_arg)
    return function(params)
        local args = vim.deepcopy(base_args)
        if params.method == FORMATTING then
            return args
        end

        local range = params.range
        table.insert(args, start_arg)
        table.insert(args, range.row)
        table.insert(args, range.end_row)
        return args
    end
end
return h.make_builtin({
    name = "autopep8",
    method = {FORMATTING, RANGE_FORMATTING},
    filetypes = { "python" },
    generator_opts = {
        command = "autopep8",
        args = range_formatting_args_factory({
            "-",
        }, "--line-range"),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
