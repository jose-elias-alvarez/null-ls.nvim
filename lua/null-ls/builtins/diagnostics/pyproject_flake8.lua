return require("null-ls.builtins").diagnostics.flake8.with({
    name = "pyproject-flake8",
    meta = {
        url = "https://github.com/csachs/pyproject-flake8",
        description = "pyproject-flake8 is a flake8 wrapper to use with `pyproject.toml` configuration.",
    },
    command = "pflake8",
})
