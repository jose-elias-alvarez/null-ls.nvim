local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

local M = {}

local get_prettier_generator_args = function(common_args)
    return function(params)
        local args = vim.deepcopy(common_args)

        if params.method == FORMATTING then
            return args
        end

        local content, range = params.content, params.range

        local row, col = range.row, range.col
        local range_start = row == 1 and 0
            or vim.fn.strchars(table.concat({ unpack(content, 1, row - 1) }, "\n") .. "\n", true)
        range_start = range_start + vim.fn.strchars(vim.fn.strcharpart(unpack(content, row, row), 0, col), true)

        local end_row, end_col = range.end_row, range.end_col
        local range_end = end_row == 1 and 0
            or vim.fn.strchars(table.concat({ unpack(content, 1, end_row - 1) }, "\n") .. "\n", true)
        range_end = range_end + vim.fn.strchars(vim.fn.strcharpart(unpack(content, end_row, end_row), 0, end_col), true)

        table.insert(args, "--range-start")
        table.insert(args, range_start)
        table.insert(args, "--range-end")
        table.insert(args, range_end)

        return args
    end
end

M.black = h.make_builtin({
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "black",
        args = {
            "--quiet",
            "--fast",
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.eslint_d = h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
    },
    generator_opts = {
        command = "eslint_d",
        args = { "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.isort = h.make_builtin({
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "isort",
        args = {
            "--stdout",
            "--profile",
            "black",
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.lua_format = h.make_builtin({
    method = FORMATTING,
    filetypes = { "lua" },
    generator_opts = {
        command = "lua-format",
        args = { "-i" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.prettier = h.make_builtin({
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "css",
        "html",
        "json",
        "yaml",
        "markdown",
    },
    generator_opts = {
        command = "prettier",
        args = get_prettier_generator_args({ "--stdin-filepath", "$FILENAME" }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.prettierd = h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "css",
        "html",
        "json",
        "yaml",
        "markdown",
    },
    generator_opts = {
        command = "prettierd",
        args = get_prettier_generator_args({ "$FILENAME" }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.prettier_d_slim = h.make_builtin({
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
    },
    generator_opts = {
        command = "prettier_d_slim",
        args = get_prettier_generator_args({ "--stdin", "--stdin-filepath", "$FILENAME" }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.scalafmt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "scala" },
    generator_opts = {
        command = "scalafmt",
        args = { "--stdin" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.shfmt = h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "sh",
    },
    generator_opts = {
        command = "shfmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.stylua = h.make_builtin({
    method = FORMATTING,
    filetypes = { "lua" },
    generator_opts = { command = "stylua", args = { "-s", "-" }, to_stdin = true },
    factory = h.formatter_factory,
})

M.swiftformat = h.make_builtin({
    method = FORMATTING,
    filetypes = { "swift" },
    generator_opts = {
        command = "swiftformat",
        args = {},
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.terraform = h.make_builtin({
    method = FORMATTING,
    filetypes = { "tf", "hcl" },
    generator_opts = {
        command = "terraform",
        args = {
            "fmt",
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.trim_whitespace = h.make_builtin({
    method = FORMATTING,
    generator_opts = {
        command = "awk",
        args = { '{ sub(/[ \t]+$/, ""); print }' },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.yapf = h.make_builtin({
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "yapf",
        args = {
            "--quiet",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

return M
