return require("null-ls.builtins").code_actions.eslint.with({
    name = "xo",
    meta = {
        url = "https://github.com/xojs/xo",
        description = "❤️ JavaScript/TypeScript linter (ESLint wrapper) with great defaults",
    },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    command = "xo",
    args = { "--reporter", "json", "--stdin", "--stdin-filename", "$FILENAME" },
})
