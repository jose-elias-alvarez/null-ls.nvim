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

For diagnostics sources, you can change the format of diagnostic messages by
setting `diagnostics_format`:

```lua
local sources = {
    -- will show code and source name
    null_ls.builtins.diagnostics.shellcheck.with({ diagnostics_format = "[#{c}] #{m} (#{s})" }),
}
```

See [CONFIG](CONFIG.md) to learn about `diagnostics_format`. Note that
specifying `diagnostics_format` for a built-in will override your global
`diagnostics_format` for that source.

## Conditional registration

null-ls supports dynamic registration, meaning that you can register sources
whenever you want. To simplify this, built-ins have access to the `conditional`
option, which should be a function that returns a boolean or `nil` indicating
whether null-ls should register the source. null-ls will pass a single argument
to the function, which is a table of utilities to handle common conditional
checks (though you can use whatever you want, as long as the return value
matches).

For example, to conditionally register `stylua` by checking if the root
directory has a `stylua.toml` file:

```lua
local sources = {
    null_ls.builtins.formatting.stylua.with({
        condition = function(utils)
            return utils.root_has_file("stylua.toml")
        end,
    }),
}
```

To conditionally register one of two or more sources, you can use the
`conditional` helper, which should return a source or `nil` and will register
the first source returned.

```lua
local sources = {
    require("null-ls.helpers").conditional(function(utils)
        return utils.root_has_file(".eslintrc.js") and b.formatting.eslint_d or b.formatting.prettier
    end),
}
```

Note that if you pass conditional sources into `null_ls.config`, null-ls will
check and register them at the point that you source your plugin config. To
handle advanced dynamic registration behavior, you can use `null_ls.register`
with a relevant `autocommand` event listener.

## Available Sources

### Formatting

#### [Asmfmt](https://github.com/klauspost/asmfmt)

```lua
local sources = {null_ls.builtins.formatting.asmfmt}
```

Go Assembler Formatter that will format your assembler code in a similar way that gofmt formats your Go code.

- Filetypes: `{ "asm" }`
- Command: `asmfmt`
- Arguments: `{}`

#### [Bean Format](https://beancount.github.io/docs/running_beancount_and_generating_reports.html#bean-format)

```lua
local sources = {null_ls.builtins.formatting.bean_format}
```

This pure text processing tool will reformat Beancount input to right-align all the numbers at the same, minimal column. It left-aligns all the currencies. It only modifies whitespace.

- Filetypes: `{ "beancount" }`
- Command: `bean-format`
- Arguments: `{ "-" }`

#### [Black](https://github.com/psf/black)

```lua
local sources = {null_ls.builtins.formatting.black}
```

Black is the uncompromising Python code formatter.

- Filetypes: `{ "python" }`
- Command: `black`
- Arguments: `{ "--quiet", "--fast", "-" }`

#### [clang-format](https://www.kernel.org/doc/html/latest/process/clang-format.html)

```lua
local sources = {null_ls.builtins.formatting.clang_format}
```

clang-format is a tool to format C/C++/… code according to a set of rules and heuristics.

- Filetypes: `{ "c", "cpp", "cs", "java" }`
- Command: `clang-format`
- Arguments: `{ "-assume-filename=<FILENAME>" }`

#### [cmake-format](https://github.com/cheshirekow/cmake_format)

```lua
local sources = {null_ls.builtins.formatting.cmake_format}
```

Can format your listfiles nicely so that they don't look like crap.

- Filetypes: `{ "cmake" }`
- Command: `cmake-format`
- Arguments: `{ "-" }`

#### [Crystal Format](https://crystal-lang.org/2015/10/16/crystal-0.9.0-released.html)

```lua
local sources = {null_ls.builtins.formatting.crystal_format}
```

A tool for automatically checking and correcting the style of code in a project.

- Filetypes: `{ "crystal" }`
- Command: `crystal`
- Arguments: `{ "tool", "format" }`

#### [dfmt](https://github.com/dlang-community/dfmt)

```lua
local sources = {null_ls.builtins.formatting.dfmt}
```

dfmt is a formatter for D source code

- Filetypes: `{ "d" }`
- Command: `dfmt`
- Arguments: `{}`

#### [Dart Format](https://dart.dev/tools/dart-format)

```lua
local sources = {null_ls.builtins.formatting.dart_format}
```

Replace the whitespace in your program with formatting that follows Dart guidelines.

- Filetypes: `{ "dart" }`
- Command: `dart`
- Arguments: `{ "format" }`

#### [elm-format](https://github.com/avh4/elm-format)

```lua
local sources = {null_ls.builtins.formatting.elm_format}
```

`elm-format` formats Elm source code according to a standard set of rules based on the [official Elm Style Guide](https://elm-lang.org/docs/style-guide)

- Filetypes: `{ "elm" }`
- Command: `elm-format`
- Arguments: `{ "--stdin", "--elm-version=0.19" }`

#### [eslint_d](https://github.com/mantoni/eslint_d.js)

An absurdly fast formatter (and linter). For full integration, check out
[nvim-lsp-ts-utils](https://github.com/jose-elias-alvarez/nvim-lsp-ts-utils).

```lua
local sources = {null_ls.builtins.formatting.eslint_d}
```

- Filetypes: `{ "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }`
- Command: `eslint_d`
- Arguments: ` { "--fix-to-stdout", "--stdin", "--stdin-filepath", "$FILENAME" }`

#### [erlfmt](https://github.com/WhatsApp/erlfmt)

```lua
local sources = {null_ls.builtins.formatting.erlfmt}
```

`erlfmt` is an opinionated Erlang code formatter.

- Filetypes: `{ "erlang" }`
- Command: `erlfmt`
- Arguments: `{ "-" }`

#### [fish_indent](https://linux.die.net/man/1/fish_indent)

```lua
local sources = {null_ls.builtins.formatting.fish_indent}
```

`fish_indent` is used to indent or otherwise prettify a piece of fish code.

- Filetypes: `{ "fish" }`
- Command: `fish_indent`
- Arguments: `{}`

#### [goimports](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)

```lua
local sources = {null_ls.builtins.formatting.goimports}
```

`goimports` updates your Go import lines, adding missing ones and removing unreferenced ones.

- Filetypes: `{ "go" }`
- Command: `goimports`
- Arguments: `{}`

#### [gofmt](https://pkg.go.dev/cmd/gofmt)

```lua
local sources = {null_ls.builtins.formatting.gofmt}
```

Gofmt formats Go programs. It uses tabs for indentation and blanks for alignment. Alignment assumes that an editor is using a fixed-width font.

- Filetypes: `{ "go" }`
- Command: `gofmt`
- Arguments: `{}`

#### [gofumpt](https://github.com/mvdan/gofumpt)

```lua
local sources = {null_ls.builtins.formatting.gofumpt}
```

Enforce a stricter format than gofmt, while being backwards compatible. That is, gofumpt is happy with a subset of the formats that gofmt is happy with.

- Filetypes: `{ "go" }`
- Command: `gofumpt`
- Arguments: `{}`

#### [isort](https://github.com/PyCQA/isort)

```lua
local sources = {null_ls.builtins.formatting.isort}
```

isort is a Python
