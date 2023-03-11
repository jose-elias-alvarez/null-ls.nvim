local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "pylint",
    meta = {
        url = "https://github.com/PyCQA/pylint",
        description = [[
Pylint is a Python static code analysis tool which looks for programming
errors, helps enforcing a coding standard, sniffs for code smells and offers
simple refactoring suggestions.

If you prefer to use the older "message-id" names for these errors (i.e.
"W0612" instead of "unused-variable"), you can customize pylint's resulting
diagnostics like so:

```lua
null_ls = require("null-ls")
null_ls.setup({
  sources = {
    null_ls.builtins.diagnostics.pylint.with({
      diagnostics_postprocess = function(diagnostic)
        diagnostic.code = diagnostic.message_id
      end,
    }),
    null_ls.builtins.formatting.isort,
    null_ls.builtins.formatting.black,
    ...,
  },
})
```
]],
    },
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "pylint",
        to_stdin = true,
        args = { "--from-stdin", "$FILENAME", "-f", "json" },
        format = "json",
        check_exit_code = function(code)
            return code ~= 32
        end,
        on_output = h.diagnostics.from_json({
            attributes = {
                row = "line",
                col = "column",
                code = "symbol",
                severity = "type",
                message = "message",
                message_id = "message-id",
                symbol = "symbol",
                source = "pylint",
            },
            severities = {
                convention = h.diagnostics.severities["information"],
                refactor = h.diagnostics.severities["information"],
            },
            offsets = {
                col = 1,
                end_col = 1,
            },
        }),
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern(
                -- https://pylint.readthedocs.io/en/latest/user_guide/usage/run.html#command-line-options
                "pylintrc",
                ".pylintrc",
                "pyproject.toml",
                "setup.cfg",
                "tox.ini"
            )(params.bufname)
        end),
    },
    factory = h.generator_factory,
})
