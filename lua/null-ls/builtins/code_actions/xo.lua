return require("null-ls.builtins").code_actions.eslint.with({
    name = "xo",
    command = "xo",
    args = { "--reporter", "json", "--stdin", "--stdin-filename", "$FILENAME" },
})
