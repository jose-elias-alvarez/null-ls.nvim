return require("null-ls.builtins").diagnostics.eslint.with({
    name = "eslint_d",
    meta = {
        url = "https://github.com/mantoni/eslint_d.js/",
        description = "Like ESLint, but faster.",
        notes = {
            "Once spawned, the server will continue to run in the background. This is normal and not related to null-ls. You can stop it by running `eslint_d stop` from the command line.",
        },
    },
    command = "eslint_d",
})
