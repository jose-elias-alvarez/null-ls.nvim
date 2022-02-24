return require("null-ls.builtins").code_actions.eslint.with({
    name = "xo",
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    command = "xo",
    args = { "--reporter", "json", "--stdin", "--stdin-filename", "$FILENAME" },
})
