return require("null-ls.builtins").diagnostics.eslint.with({
    name = "xo",
    command = "xo",
    args = { "--reporter", "json", "--stdin", "--stdin-filename", "$FILENAME" },
})
