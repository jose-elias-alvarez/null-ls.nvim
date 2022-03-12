return require("null-ls.builtins").code_actions.eslint.with({
    name = "eslint_d",
    command = "eslint_d",
    meta = {
        url = "https://github.com/mantoni/eslint_d.js",
        description = "Injects actions to fix ESLint issues or ignore broken rules. Like ESLint, but faster.",
    },
})
