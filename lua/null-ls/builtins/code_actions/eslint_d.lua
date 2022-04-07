return require("null-ls.builtins").code_actions.eslint.with({
    name = "eslint_d",
    command = "eslint_d",
    meta = {
        url = "https://github.com/mantoni/eslint_d.js",
        description = "Injects actions to fix ESLint issues or ignore broken rules. Like ESLint, but faster.",
        notes = {
            "Once spawned, the server will continue to run in the background. This is normal and not related to null-ls. You can stop it by running `eslint_d stop` from the command line.",
        },
    },
})
