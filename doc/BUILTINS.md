# Using built-in sources

null-ls includes a library of built-in sources meant to provide out-of-the-box
functionality. Built-in sources run with optimizations to reduce startup time
and enable user customization.

## Loading and registering

null-ls exposes built-ins on `null_ls.builtins`, which contains the following
groups of sources:

```lua
-- code action sources
null_ls.builtins.code_actions

-- diagnostic sources
null_ls.builtins.diagnostics

-- formatting sources
null_ls.builtins.formatting
```

You can then register sources by passing a `sources` list into your `config`
function:

```lua
local null_ls = require("null-ls")

-- register any number of sources simultaneously
local sources = {
    null_ls.builtins.formatting.prettier,
    null_ls.builtins.diagnostics.write_good,
    null_ls.builtins.code_actions.gitsigns,
}

null_ls.config({ sources = sources })
```

Built-in sources also have access to a special method, `with()`, which modifies
the source's default options. For example, you can alter a source's file types
as follows:

```lua
local sources = {
    null_ls.builtins.formatting.prettier.with({
        filetypes = { "html", "json", "yaml", "markdown" },
    }),
}
```

See the descriptions below or the relevant `builtins` source file to see the
default options passed to each built-in source.

## Available Sources

### Formatting

#### [StyLua](https://github.com/JohnnyMorganz/StyLua)

```lua
local sources = {null_ls.builtins.formatting.stylua}
```

A fast and opinionated Lua formatter written in Rust. Highly recommended!

- Filetypes: `{ "lua" }`
- Command: `stylua`
- Arguments: `{ "-" }`

#### [LuaFormatter](https://github.com/Koihik/LuaFormatter)

A flexible but slow Lua formatter. Not recommended for formatting on save.

```lua
local sources = {null_ls.builtins.formatting.lua_format}
```

- Filetypes: `{ "lua" }`
- Command: `lua-format`
- Arguments: `{ "-i" }`

#### [Prettier](https://github.com/prettier/prettier)

Supports both `textDocument/formatting` and `textDocument/rangeFormatting`
(may not work on some filetypes).

```lua
local sources = {null_ls.builtins.formatting.prettier}
```

- Filetypes: `{ "javascript", "javascriptreact", "typescript", "typescriptreact", "css", "html", "json", "yaml", "markdown" }`
- Command: `prettier`
- Arguments: `{ "--stdin-filepath", "$FILENAME" }`

#### [prettier_d_slim](https://github.com/mikew/prettier_d_slim)

A faster version of Prettier that doesn't seem to work well on non-JavaScript
filetypes. Supports both `textDocument/formatting` and `textDocument/rangeFormatting`
(may not work on some filetypes).

```lua
local sources = {null_ls.builtins.formatting.prettier_d_slim}
```

- Filetypes: `{ "javascript", "javascriptreact", "typescript", "typescriptreact" }`
- Command: `prettier_d_slim`
- Arguments: ` { "--stdin", "--stdin-filepath", "$FILENAME" }`

#### [prettierd](https://github.com/fsouza/prettierd)

Another "Prettier, but faster" formatter, with better support for non-JavaScript
filetypes.

- Filetypes: `{ "javascript", "javascriptreact", "typescript", "typescriptreact", "css", "html", "json", "yaml", "markdown" }`
- Command: `prettierd`
- Arguments: `{ "$FILENAME" }`

#### [eslint_d](https://github.com/mantoni/eslint_d.js)

An absurdly fast formatter (and linter). For full integration, check out
[nvim-lsp-ts-utils](https://github.com/jose-elias-alvarez/nvim-lsp-ts-utils).

```lua
local sources = {null_ls.builtins.formatting.eslint_d}
```

- Filetypes: `{ "javascript", "javascriptreact", "typescript", "typescriptreact" }`
- Command: `eslint_d`
- Arguments: ` { "--fix-to-stdout", "--stdin", "--stdin-filepath", "$FILENAME" }`

#### trim_whitespace

A simple wrapper around `awk` to remove trailing whitespace.

```lua
local sources = { null_ls.builtins.formatting.trim_whitespace.with({ filetypes = { ... } }) }
```

- Filetypes: none (must specify in `with()`, as above)
- Command: `awk`
- Arguments: `{ '{ sub(/[ \t]+$/, ""); print }' }`

### Diagnostics

#### [ESLint](https://github.com/eslint/eslint)

A linter for the JavaScript ecosystem. Note that the null-ls builtin requires
your ESLint executable to be available on your `$PATH`. To use local (project)
executables, use the integration in
[nvim-lsp-ts-utils](https://github.com/jose-elias-alvarez/nvim-lsp-ts-utils).

```lua
local sources = {null_ls.builtins.diagnostics.eslint}

-- if you want to use eslint_d
local sources = {null_ls.builtins.diagnostics.eslint.with({command = "eslint_d"})}
```

- Filetypes: `{ "javascript", "javascriptreact", "typescript", "typescriptreact" }`
- Command: `eslint`
- Arguments: `{ "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" }`

#### [hadolint](https://github.com/hadolint/hadolint)

A smarter Dockerfile linter that helps you build best practice Docker images.

```lua
local sources = {null_ls.builtins.diagnostics.hadolint}
```

- Filetypes: `{ "dockerfile" }`
- Command: `hadolint`
- Arguments: `{ "--no-fail", "--format=json", "$FILENAME" }`

#### [write-good](https://github.com/btford/write-good)

English prose linter.

```lua
local sources = {null_ls.builtins.diagnostics.write_good}
```

- Filetypes: `{ "markdown" }`
- Command: `write-good`
- Arguments: `{ "--text=$TEXT", "--parse" }`

#### [markdownlint](https://github.com/DavidAnson/markdownlint) via [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli)

Markdown style and syntax checker.

```lua
local sources = {null_ls.builtins.diagnostics.markdownlint}
```

- Filetypes: `{ "markdown" }`
- Command: `markdownlint`
- Arguments: `{ "--stdin" }`

#### [vale](https://docs.errata.ai/vale/about)

Syntax-aware linter for prose built with speed and extensibility in mind.

vale does not include a syntax by itself, so you probably need to grab a
`vale.ini` (at "~/.vale.ini") and a `StylesPath` (somewhere, pointed from
`vale.ini`) from
[here](https://docs.errata.ai/vale/about#open-source-configurations).

```lua
local sources = {null_ls.builtins.diagnostics.vale}
```

- Filetypes: `{ "markdown", "tex" }`
- Command: `vale`
- Arguments: `{ "--no-exit", "--output=JSON", "$FILENAME" }`

### tl check via [teal](https://github.com/teal-language/tl)

Turns `tl check` into a linter. It writes the buffer's content to a temporary
file, so it works on change, not (only) on save!

Note that Neovim doesn't support Teal files out-of-the-box, so you'll probably
want to use [vim-teal](https://github.com/teal-language/vim-teal).

```lua
local sources = {null_ls.builtins.diagnostics.teal}
```

- Filetypes: `{ "teal" }`
- Command: `tl`
- Arguments: `{ "check", "$FILENAME" }`

#### [misspell](https://github.com/client9/misspell)

Correct commonly misspelled English words in source files

```lua
local sources = {null_ls.builtins.diagnostics.misspell}
```

- Filetypes: `{ "*" }`
- Command: `misspell`
- Arguments: `{ "$FILENAME" }`
