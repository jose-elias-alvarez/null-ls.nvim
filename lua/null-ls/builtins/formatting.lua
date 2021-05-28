local methods = require("null-ls.methods")
local helpers = require("null-ls.helpers")

local FORMATTING = methods.internal.FORMATTING

local M = {}
M.lua_format = {
    method = FORMATTING,
    filetypes = {"lua"},
    generator = helpers.formatter_factory(
        {
            command = "lua-format",
            args = {"--single-quote-to-double-quote", "-i"},
            to_stdin = true,
            timeout = 2500
        })
}

M.prettier = {
    method = FORMATTING,
    filetypes = {
        "javascript", "javascriptreact", "typescript", "typescriptreact", "css",
        "html", "json", "yaml", "markdown"
    },
    generator = helpers.formatter_factory(
        {
            command = "prettier",
            args = {"--stdin-filepath", "$FILENAME"},
            to_stdin = true
        })
}

M.prettier_d_slim = {
    method = FORMATTING,
    filetypes = {
        "javascript", "javascriptreact", "typescript", "typescriptreact"
    },
    generator = helpers.formatter_factory(
        {
            command = "prettier_d_slim",
            args = {"--stdin", "--stdin-filepath", "$FILENAME"},
            to_stdin = true
        })
}

M.eslint_d = {
    method = FORMATTING,
    filetypes = {
        "javascript", "javascriptreact", "typescript", "typescriptreact"
    },
    generator = helpers.formatter_factory(
        {
            command = "eslint_d",
            args = {
                "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME"
            },
            to_stdin = true
        })
}

return M
