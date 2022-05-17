# Contributing

## General

- Before committing, please go through the following steps:

1. Lint Lua files with [selene](https://github.com/Kampfkarren/selene)
2. Format Lua files with [StyLua](https://github.com/JohnnyMorganz/StyLua)
3. If you've updated documentation, format Markdown files with
   [Prettier](https://github.com/prettier/prettier)

   All are available as null-ls built-ins. Failing to lint and format files will
   cause CI failures, which will prevent your PR from getting merged.

   Optionally, you can install
   [Pre-Commit](https://pre-commit.com/index.html#install) hooks by cloning the
   project and running `make install-hooks` to locally enforce checks on commit.

- Use the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
  style for your commits.

- Squash your commits so that one commit represents one complete change.

- Mark your PR as WIP until it's ready to merge.

- Make sure tests are passing by running `make test` in the root of the project.
  Smaller features / fixes should have unit test coverage, and larger features
  should have E2E coverage.

- We use Plenary's test suite, which uses a stripped-down version of
  [busted](https://github.com/Olivine-Labs/busted). If you're unsure how to
  write tests for your PR, please let us know and we can help.

## Contributing built-ins

- Check if there is an open issue requesting the built-in you are adding and
  mention in your PR that it closes any relevant issue(s).

- Check other built-in sources for examples and, whenever possible, use helpers
  to reduce the number of lines of code in your PR.

- A built-in source's arguments are the minimal arguments required for the
  source to work. Leave out non-essential arguments.

- Built-in sources should target the latest available version of the underlying
  program unless there is a compelling and widespread reason to use an older
  version. If older versions require different arguments, mention that in the
  documentation. If they require a different parser, create a separate built-in.

- Make sure your built-in source has a `name`.

- Add the necessary `meta` field to your built-in so that we can generate extra
  documentation (basic information comes from the built-in's definition).
  Metadata should have the following structure:

```lua
local my_builtin = require("null-ls.helpers").make_builtin({
    -- place after built-in definition
    meta = {
        url = "https://github.com/my-builtin-repo",
        description = "Description of my built-in and what it does",
        notes = {
            "If present, we'll convert this table into a Markdown list",
        },
    },
})
```

## Sources

### Diagnostics

- Include all the information provided by the source. These are the available
  fields:

```lua
-- make sure ranges are 1-indexed (and offset if not)
local diagnostic = {
    message, -- string
    severity, -- 1 (error), 2 (warning), 3 (information), 4 (hint)
    row, -- number, optional (defaults to first line)
    col, -- number, optional (defaults to beginning of line)
    end_row, -- number, optional (defaults to row)
    end_col, -- number, optional (defaults to end of line),
    source, -- string, optional (defaults to "null-ls")
    code, -- number, optional
    filename, -- string, optional
    bufnr, -- number, optional
}
```

- Try to make sure `col` and `end_col` match the precise range of the
  diagnostic. If you're using our diagnostic helpers, you can use the `offset`
  override to adjust the range.

  An easy way to check the range is to use a theme like
  [tokyonight](https://github.com/folke/tokyonight.nvim) or
  [sonokai](https://github.com/sainnhe/sonokai) that underlines LSP diagnostics.

- Do not include the source's name or code in the message.

- If at all possible, please add one or more tests to check whether your source
  produces the correct output given an actual raw diagnostic. See [the
  existing tests](../test/spec/builtins/diagnostics_spec.lua) for examples.

- If your source can produce project-level diagnostics (i.e. diagnostics for more
  than one file at a time), use the `multiple_files` option described in
  [HELPERS](./HELPERS.md).

  - Specify that your source supports project diagnostics in its documentation.

  - Make sure each multi-file diagnostic includes either a `filename` or a
    `bufnr` so null-ls can then publish diagnostics properly. If specified,
    `filename` should be an absolute path.

  - To prevent peformance issues, multi-file sources should default to the
    `ON_SAVE` method.
