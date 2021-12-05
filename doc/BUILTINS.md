<!-- markdownlint-configure-file
{
  "line-length": false,
  "no-duplicate-header": false
}
-->

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

-- hover sources
null_ls.builtins.hover

-- completion sources
null_ls.builtins.completion
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

To run built-in sources, the command specified below must be available on your
`$PATH` and visible to Neovim. For example, to check if `eslint` is available,
run the following (Vim, not Lua) command:

```vim
" should echo 1 if available (and 0 if not)
:echo executable("eslint")
```

## Configuration

Built-in sources have access to a special method, `with()`, which modifies the
source's default options. See the descriptions below or the relevant source file
to see the default options passed to each built-in source.

### Filetypes

You can override a source's default filetypes as follows:

```lua
local sources = {
    null_ls.builtins.formatting.prettier.with({
        filetypes = { "html", "json", "yaml", "markdown" },
    }),
}
```

If you see `filetypes = {}` in a source's description, that means the source is
active for all filetypes by default. You may want to define a specific list of
filetypes to avoid conflicts or other issues.

You can also pass a list of specifically disabled filetypes:

```lua
local sources = {
    null_ls.builtins.code_actions.gitsigns.with({
        disabled_filetypes = { "lua" },
    }),
}
```

null-ls is always inactive in non-file buffers (e.g. file trees, finders) so
theres's no need to specify them here.

### Arguments

To add more arguments to a source's defaults, use `extra_args`:

```lua
local sources = {
    null_ls.builtins.formatting.shfmt.with({
        extra_args = { "-i", "2", "-ci" }
      })
  }
```

You can also override a source's arguments entirely using `with({ args = your_args })`.

Both `args` and `extra_args` can also be functions that accept a single
argument, `params`, which is an object containing information about editor
state. LSP options (e.g. formatting options) are available as `params.options`,
making it possible to dynamically set arguments based on these options:

```lua
local sources = {
    null_ls.builtins.formatting.prettier.with({
        extra_args = function(params)
            return params.options
                and params.options.tabSize
                and {
                    "--tab-width",
                    params.options.tabSize,
                }
        end,
    }),
}
```

### Expansion

Note that environment variables and `~` aren't expanded in arguments. As a
workaround, you can use `vim.fn.expand`:

```lua
local sources = {
    null_ls.builtins.formatting.stylua.with({
        extra_args = { "--config-path", vim.fn.expand("~/.config/stylua.toml") },
    }),
}
```

### Diagnostics format

For diagnostics sources, you can change the format of diagnostic messages by
setting `diagnostics_format`:

```lua
local sources = {
    -- will show code and source name
    null_ls.builtins.diagnostics.shellcheck.with({
        diagnostics_format = "[#{c}] #{m} (#{s})"
    }),
}
```

See [CONFIG](CONFIG.md) to learn about the structure of `diagnostics_format`.
Note that specifying `diagnostics_format` for a built-in will override your
global `diagnostics_format` for that source.

### Diagnostics performance

If you have performance issues with a diagnostic source, you can configure any
it to run on save (not on each change) by overriding `method`:

```lua
local sources = {
    null_ls.builtins.diagnostics.pylint.with({
        method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
    }),
}
```

## Local executables

To prefer using a local executable for a built-in, use the `prefer_local`
option. This will cause null-ls to search upwards from the current buffer's
directory, try to find a local executable at each parent directory, and fall
back to a global executable if it can't find one locally.

`prefer_local` can be a boolean or a string, in which case it's treated as a
prefix. For example, the following settings will cause null-ls to search for
`node_modules/.bin/prettier`:

```lua
local sources = {
    null_ls.builtins.formatting.prettier.with({
        prefer_local = "node_modules/.bin",
    }),
}
```

To _only_ use a local executable without falling back, use `only_local`, which
accepts the same options.

By default, these options will also set the `cwd` of the spawned process to the
parent directory of the local executable (if found). You can override this by
manually setting `cwd` to a function that should return your preferred `cwd`.

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

#### [asmfmt](https://github.com/klauspost/asmfmt)

##### About

Format your assembler code in a similar way that `gofmt` formats your `go` code.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.asmfmt }
```

##### Defaults

- `filetypes = { "asm" }`
- `command = "asmfmt"`
- `args = {}`

#### [autopep8](https://github.com/hhatto/autopep8)

##### About

Formatter for `python` files.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.autopep8 }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "autopep8"`
- `args = { "-" }`

#### [bean-format](https://beancount.github.io/docs/running_beancount_and_generating_reports.html#bean-format)

##### About

This pure text processing tool will reformat `beancount` input to right-align all
the numbers at the same, minimal column.

- It left-aligns all the currencies.
- It only modifies whitespace.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.bean_format }
```

##### Defaults

- `filetypes = { "beancount" }`
- `command = "bean-format"`
- `args = { "-" }`

#### [black](https://github.com/psf/black)

##### About

Uncompromising Python code formatter.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.black }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "black"`
- `args = { "--quiet", "--fast", "-" }`

#### [clang-format](https://www.kernel.org/doc/html/latest/process/clang-format.html)

##### About

Tool to format `C`/`C++`/… code according to a set of rules and heuristics.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.clang_format }
```

##### Defaults

- `filetypes = { "c", "cpp", "cs", "java" }`
- `command = "clang-format"`
- `args = { "-assume-filename=<FILENAME>" }`

#### [cmake-format](https://github.com/cheshirekow/cmake_format)

##### About

Format your `listfiles` nicely so that they don't look like crap.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.cmake_format }
```

##### Defaults

- `filetypes = { "cmake" }`
- `command = "cmake-format"`
- `args = { "-" }`

#### [codespell](https://github.com/codespell-project/codespell)

##### About

`codespell` fix common misspellings in text files.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.codespell }
```

##### Defaults

- `filetypes = {}`
- `command = "codespell"`
- `args = { "--write-changes", "$FILENAME" }`

#### [crystal-format](https://crystal-lang.org/2015/10/16/crystal-0.9.0-released.html)

##### About

A tool for automatically checking and correcting the style of code in a project.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.crystal_format }
```

##### Defaults

- `filetypes = { "crystal" }`
- `command = "crystal"`
- `args = { "tool", "format" }`

#### [dart-format](https://dart.dev/tools/dart-format)

##### About

Replace the whitespace in your program with formatting that follows Dart guidelines.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.dart_format }
```

##### Defaults

- `filetypes = { "dart" }`
- `command = "dart"`
- `args = { "format" }`

#### [Deno Formatter](https://deno.land/manual/tools/formatter)

##### About

Use [Deno](https://deno.land) to format TypeScript and JavaScript code.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.deno_fmt }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }`
- `command = "deno"`
- `args = { "fmt", "-"}`

#### [dfmt](https://github.com/dlang-community/dfmt)

##### About

Formatter for `D` source code.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.dfmt }
```

##### Defaults

- `filetypes = { "d" }`
- `command = "dfmt"`
- `args = {}`

#### [elm-format](https://github.com/avh4/elm-format)

##### About

`elm-format` formats Elm source code according to a standard set of rules based
on the [official Elm Style Guide](https://elm-lang.org/docs/style-guide).

##### Usage

```lua
local sources = { null_ls.builtins.formatting.elm_format }
```

##### Defaults

- `filetypes = { "elm" }`
- `command = "elm-format"`
- `args = { "--stdin", "--elm-version=0.19" }`

#### [erlfmt](https://github.com/WhatsApp/erlfmt)

##### About

Opinionated `erlang` code formatter.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.erlfmt }
```

##### Defaults

- `filetypes = { "erlang" }`
- `command = "erlfmt"`
- `args = { "-" }`

#### [ESLint](https://github.com/eslint/eslint)

##### About

Fixes problems in your JavaScript code.

- Slow and not suitable for formatting on save. If at all possible, use
  `eslint_d` (described below).

##### Usage

```lua
local sources = { null_ls.builtins.formatting.eslint }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }`
- `command = "eslint"`
- `args = { "--fix-dry-run", "--format", "JSON", "--stdin", "--stdin-filename", "$FILENAME" }`

#### [eslint_d](https://github.com/mantoni/eslint_d.js)

##### About

An absurdly fast formatter (and linter).

##### Usage

```lua
local sources = { null_ls.builtins.formatting.eslint_d }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }`
- `command = "eslint_d"`
- `args = { "--fix-to-stdout", "--stdin", "--stdin-filepath", "$FILENAME" }`

#### [fish_indent](https://linux.die.net/man/1/fish_indent)

##### About

Indent or otherwise prettify a piece of `fish` code.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.fish_indent }
```

##### Defaults

- `filetypes = { "fish" }`
- `command = "fish_indent"`
- `args = {}`

#### [fixjson](https://github.com/rhysd/fixjson)

##### About

`fixjson` is a JSON file fixer/formatter for humans using (relaxed) JSON5.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.fixjson }
```

##### Defaults

- `filetypes = { "json" }`
- `command = "fixjson"`
- `args = {}`

#### [fnlfmt](https://git.sr.ht/~technomancy/fnlfmt)

```lua
local sources = {null_ls.builtins.formatting.fnlfmt}
```

`fnlfmt` is a Fennel code formatter which follows established lisp conventions when determining how to format a given piece of code.

- `filetypes: { "fennel", "fnl" }`
- `command: "fnlfmt"`
- `args: { "--fix" }`

#### [formatR](https://github.com/yihui/formatR)

##### About

- Format R code automatically.
- Supports both `textDocument/formatting` and `textDocument/rangeFormatting`.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.format_r }
```

##### Defaults

- `filetypes = { "r", "rmd" }`
- `command = "R"`
- `args = { "--slave", "--no-restore", "--no-save", "-e", 'formatR::tidy_source(source="stdin")' }`

#### [fprettify](https://github.com/pseewald/fprettify)

##### About

`fprettify` is an auto-formatter for modern Fortran code that imposes strict whitespace formatting.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.fprettify }
```

##### Defaults

- `filetypes = { "fortran" }`
- `command = "fprettify"`
- `args = { "--silent" }`

#### [gofmt](https://pkg.go.dev/cmd/gofmt)

##### About

Formats `go` programs.

- It uses tabs for indentation and blanks for alignment.
- Alignment assumes that an editor is using a fixed-width font.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.gofmt }
```

##### Defaults

- `filetypes = { "go" }`
- `command = "gofmt"`
- `args = {}`

#### [gofumpt](https://github.com/mvdan/gofumpt)

##### About

Enforce a stricter format than `gofmt`, while being backwards compatible.
That is, `gofumpt` is happy with a subset of the formats that `gofmt` is happy with.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.gofumpt }
```

##### Defaults

- `filetypes = { "go" }`
- `command = "gofumpt"`
- `args = {}`

#### [goimports](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)

##### About

Updates your Go import lines, adding missing ones and removing unreferenced ones.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.goimports }
```

##### Defaults

- `filetypes = { "go" }`
- `command = "goimports"`
- `args = {}`

#### [golines](https://pkg.go.dev/github.com/segmentio/golines)

##### About

Applies a base formatter (eg. `goimports` or `gofmt`), then shorten long lines of code.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.golines }
```

##### Defaults

- `filetypes = { "go" }`
- `command = "golines"`
- `args = {}`

#### [google-java-format](https://github.com/google/google-java-format)

##### About

Reformats Java source code to comply with Google Java Style.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.google_java_format }
```

If you want 4 space indentation use:

```lua
local sources = {
  null_ls.builtins.formatting.google_java_format.with({
    extra_args = { "--aosp" },
  }),
}
```

##### Defaults

- `filetypes = { "java" }`
- `command = "google-java-format"`
- `args = { "-" }`

#### [isort](https://github.com/PyCQA/isort)

##### About

`python` utility / library to sort imports alphabetically and automatically
separate them into sections and by type.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.isort }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "isort"`
- `args = { "--stdout", "--profile", "black", "-" }`

#### [reorder_python_imports](https://github.com/asottile/reorder_python_imports)

##### About

`python` utility tool for automatically reordering python imports. Similar to isort but uses static analysis more.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.reorder_python_imports }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "reorder-python-imports"`
- `args = { "-", "--exit-zero-even-if-changed" }`

#### [json.tool](https://docs.python.org/3/library/json.html#module-json.tool)

##### About

Provides a simple command line interface to validate and pretty-print `JSON` objects.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.json_tool }
```

##### Defaults

- `filetypes = { "json" }`
- `command = "python"`
- `args = { "-m", "json.tool" }`

#### [LuaFormatter](https://github.com/Koihik/LuaFormatter)

##### About

A flexible but slow `lua` formatter. Not recommended for formatting on save.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.lua_format }
```

##### Defaults

- `filetypes = { "lua" }`
- `command = "lua-format"`
- `args = { "-i" }`

#### [markdownlint](https://github.com/igorshubovych/markdownlint-cli)

##### About

Can fix some (but not all!) `markdownlint` issues. If possible, use
[Prettier](https://github.com/prettier/prettier), which can also fix Markdown
files.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.markdownlint }
```

##### Defaults

- `filetypes = { "markdown" }`
- `command = "markdownlint"`
- `args = { "--fix", "$FILENAME" }`

#### [Mix](https://hexdocs.pm/mix/1.12/Mix.html)

##### About

Build tool that provides tasks for creating, compiling, and testing `elixir` projects,
managing its dependencies, and more.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.mix }
```

##### Defaults

- `filetypes = { "elixir" }`
- `command = "mix"`
- `args = { "format", "-" }`

#### [nginxbeautifier](https://github.com/vasilevich/nginxbeautifier)

##### About

Beautifies and formats `nginx` configuration files.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.nginx_beautifier }
```

##### Defaults

- `filetypes = { "nginx" }`
- `command = "nginxbeautifier"`
- `args = { "-i" }`

#### [nixfmt](https://github.com/serokell/nixfmt)

##### About

`nixfmt` is a formatter for Nix code, intended to easily apply a uniform style.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.nixfmt }
```

##### Defaults

- `filetypes = { "nix" }`
- `command = "nixfmt"`

#### [perltidy](http://perltidy.sourceforge.net/)

##### About

`perl` script which indents and reformats `perl` scripts to make them
easier to read. If you write `perl` scripts, or spend much time reading them,
you will probably find it useful.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.perltidy }
```

##### Defaults

- `filetypes = { "perl" }`
- `command = "perltidy"`
- `args = { "-q" }`

#### [phpcbf](https://github.com/squizlabs/PHP_CodeSniffer)

##### About

Tokenizes PHP files and detects violations of a defined set of coding standards.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.phpcbf }
```

##### Defaults

- `filetypes = { "php" }`
- `command = "phpcbf"`
- `args = { "--standard=PSR12", "-" }`

#### [php-cs-fixer](https://github.com/FriendsOfPhp/PHP-CS-Fixer)

##### About

Formatter for `php` files.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.phpcsfixer }
```

##### Defaults

- `filetypes = { "php" }`
- `command = "php-cs-fixer"`
- `args = { '--no-interaction', '--quiet', 'fix', "$FILENAME" }`

#### [prettier](https://github.com/prettier/prettier)

##### About

- Supports both `textDocument/formatting` and `textDocument/rangeFormatting`.
- Supports more filetypes such as
  [Svelte](https://github.com/sveltejs/prettier-plugin-svelte) and
  [TOML](https://github.com/bd82/toml-tools/tree/master/packages/prettier-plugin-toml)
  via plugins. These filetypes are not enabled by default, but you can follow
  the instructions [here](#filetypes) to define your own list of filetypes.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.prettier }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "css", "scss", "less", "html", "json", "yaml", "markdown", "graphql" }`
- `command = "prettier"`
- `args = { "--stdin-filepath", "$FILENAME" }`

#### [prettier_d_slim](https://github.com/mikew/prettier_d_slim)

##### About

- A faster version of `prettier` that doesn't seem to work well on
  non-JavaScript filetypes.
- Supports both `textDocument/formatting` and `textDocument/rangeFormatting`
- May not work on some filetypes.
- `prettierd` is more stable and recommended.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.prettier_d_slim }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "css", "scss", "less", "html", "json", "yaml", "markdown", "graphql" }`
- `command = "prettier_d_slim"`
- `args = { "--stdin", "--stdin-filepath", "$FILENAME" }`

#### [prettierd](https://github.com/fsouza/prettierd)

##### About

- Another "`prettier`, but faster" formatter, with better support for non-JavaScript
  filetypes.
- Does not support `textDocument/rangeFormatting`.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.prettierd }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "css", "scss", "less", "html", "json", "yaml", "markdown", "graphql" }`
- `command = "prettierd"`
- `args = { "$FILENAME" }`

#### [prismaFmt](https://github.com/prisma/prisma-engines)

##### About

Formatter for prisma filetype.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.prismaFmt }
```

##### Defaults

- `filetypes = { "prisma" }`
- `command = "prisma-fmt"`
- `args = { "format", "-i", "$FILENAME" }`

#### [qmlformat](https://doc-snapshots.qt.io/qt6-dev/qtquick-tools-and-utilities.html#qmlformat)

##### About

`qmlformat` is a tool that automatically formats QML files in accordance with
the QML Coding Conventions.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.qmlformat }
```

##### Defaults

- `filetypes = { "qml" }`
- `command = "qmlformat"`
- `args = { "-i", "$FILENAME" }`

#### [reorder_python_imports](https://pypi.org/project/reorder-python-imports/)

##### About

Tool for automatically reordering python imports. Similar to `isort` but uses static analysis more.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.reorder_python_imports }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "reorder-python-imports"`
- `args = { "-", "--exit-zero-even-if-changed" }`

#### [rubocop](https://github.com/rubocop/rubocop)

##### About

Ruby static code analyzer and formatter, based on the community Ruby style guide.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.rubocop }
```

##### Defaults

- `filetypes = { "ruby" }`
- `command = "rubocop"`
- `args = { "--auto-correct", "-f", "quiet", "--stderr", "--stdin", "$FILENAME" }`

#### [rufo](https://github.com/ruby-formatter/rufo)

##### About

Opinionated `ruby` formatter.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.rufo }
```

##### Defaults

- `filetypes = { "ruby" }`
- `command = "rufo"`
- `args = { "-x" }`

#### [rustfmt](https://github.com/rust-lang/rustfmt)

##### About

A tool for formatting `rust` code according to style guidelines.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.rustfmt }
```

##### Defaults

- `filetypes = { "rust" }`
- `command = "rustfmt"`
- `args = { "--emit=stdout", "--edition=2018" }`

#### [rustywind](https://github.com/avencera/rustywind)

##### About

CLI for organizing Tailwind CSS classes.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.rustywind }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "html", }`
- `command = "rustywind"`
- `args = { "--stdin" }`

#### [scalafmt](https://github.com/scalameta/scalafmt)

##### About

Code formatter for Scala

##### Usage

```lua
local sources = { null_ls.builtins.formatting.scalafmt }
```

##### Defaults

- `filetypes = { "scala" }`
- `command = "scalafmt"`
- `args = { "--stdin" }`

#### [shellharden](https://github.com/anordal/shellharden)

##### About

Hardens shell scripts by quoting variables, replacing `` `function_call` `` with `$(function_call)`, and more.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.shellharden }
```

##### Defaults

- `filetypes = { "sh" }`
- `command = "shellharden"`
- `args = { "--transform", "$FILENAME" }`

#### [shfmt](https://github.com/mvdan/sh)

##### About

A `shell` parser, formatter, and interpreter with `bash` support.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.shfmt }
```

##### Defaults

- `filetypes = { "sh" }`
- `command = "shfmt"`
- `args = { "-filename", "$FILENAME" }`

#### [sqlformat](https://manpages.ubuntu.com/manpages/xenial/man1/sqlformat.1.html)

##### About

The `sqlformat` command-line tool can be used to reformat SQL file
according to specified options.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.sqlformat }
```

##### Defaults

- `filetypes = { "sql" }`
- `command = "sqlformat"`
- `args = { "--reindent", "-" }`

#### [standardrb](https://github.com/testdouble/standard)

##### About

Ruby Style Guide, with linter & automatic code fixer. Based on Rubocop.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.standardrb }
```

##### Defaults

- `filetypes = { "ruby" }`
- `command = "standardrb"`
- `args = { "--fix", "--format", "quiet", "--stderr", "--stdin", "$FILENAME" }`

#### [Stylelint](https://github.com/stylelint/stylelint)

##### About

A mighty, modern linter that helps you avoid errors and enforce conventions in your styles.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.stylelint }
```

##### Defaults

- `filetypes = { "scss", "less", "css", "sass" }`
- `command = "stylelint"`
- `args = { "--fix", "--stdin", "-" }`

#### [styler](https://github.com/r-lib/styler)

##### About

- Non-invasive pretty printing of R code.
- Supports both `textDocument/formatting` and `textDocument/rangeFormatting`.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.styler }
```

##### Defaults

- `filetypes = { "r", "rmd" }`
- `command = "R"`
- `args = { "--slave", "--no-restore", "--no-save", "-e", 'con=file("stdin");output=styler::style_text(readLines(con));close(con);print(output, colored=FALSE)' }`

#### [StyLua](https://github.com/JohnnyMorganz/StyLua)

##### About

- A fast and opinionated Lua formatter written in Rust. Highly recommended!
- Supports both `textDocument/formatting` and `textDocument/rangeFormatting`.
  Note that as of now, the range must include a top-level statement for range
  formatting to work (see [this
  issue](https://github.com/JohnnyMorganz/StyLua/issues/239) for details).

##### Usage

```lua
local sources = { null_ls.builtins.formatting.stylua }
```

##### Defaults

- `filetypes = { "lua" }`
- `command = "stylua"`
- `args = { "-s", "-" }`

#### [Surface](https://hexdocs.pm/surface_formatter/readme.html)

##### About

A code formatter for Surface, the server-side rendering component library for Phoenix.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.surface }
```

##### Defaults

- `filetypes = { "elixir", "surface" }`
- `command = "mix"`
- `args = { "surface.format", "-" }`

#### [swiftformat](https://github.com/nicklockwood/SwiftFormat)

##### About

`SwiftFormat` is a code library and command-line tool for reformatting
`swift` code on macOS or Linux.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.swiftformat }
```

##### Defaults

- `filetypes = { "swift" }`
- `command = "swiftformat"`
- `args = {}`

#### [Taplo](https://taplo.tamasfe.dev)

#### About

A versatile, feature-rich TOML toolkit.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.taplo }
```

##### Defaults

- `filetypes = { "toml" }`
- `command = "taplo"`
- `args = { "format", "-" }`

#### [terraform_fmt](https://www.terraform.io/docs/cli/commands/fmt.html)

##### About

The `terraform-fmt` command is used to rewrite `terraform`
configuration files to a canonical format and style.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.terraform_fmt }
```

##### Defaults

- `filetypes = { "tf", "hcl" }`
- `command = "terraform"`
- `args = { "fmt", "-" }`

#### trim_newlines

##### About

A simple wrapper around `awk` to remove trailing newlines.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.trim_newlines }
```

##### Defaults

- `filetypes = { }`
- `command = "awk"`
- `args = { 'NF{print s $0; s=""; next} {s=s ORS}' }`

#### trim_whitespace

##### About

A simple wrapper around `awk` to remove trailing whitespace.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.trim_whitespace }
```

##### Usage

- `filetypes = { }`
- `command = "awk"`
- `args = { '{ sub(/[ \t]+$/, ""); print }' }`

#### [uncrustify](https://github.com/uncrustify/uncrustify)

##### About

A source code beautifier for `C`, `C++`, `C#`, `ObjectiveC`, `D`, `java`,
`pawn` and `VALA`.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.uncrustify }
```

##### Defaults

- `filetypes = { "c", "cpp", "cs", "java" }`
- `command = "uncrustify"`
- `args = { "-q", "-l <LANG>" }`

#### [yapf](https://github.com/google/yapf)

##### About

Formatter for `python` files

- Supports both `textDocument/formatting` and `textDocument/rangeFormatting`.
  - `textDocument/rangeFormatting` is line-based.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.yapf }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "yapf"`
- `args = { "--quiet" }`

#### [zigfmt](https://github.com/ziglang/zig)

##### About

Reformat Zig source into canonical form.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.zigfmt }
```

##### Defaults

- `filetypes = { "zig" }`
- `command = "zig"`
- `args = { "fmt", "--stdin" }`

### Diagnostics

#### [ansible-lint](https://github.com/ansible-community/ansible-lint)

##### About

Linter for Ansible playbooks, roles and collections.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.ansiblelint }
```

##### Defaults

- `filetypes = { "yaml" }`
- `command = "ansible-lint"`
- `args = { "--parseable-severity", "-q", "--nocolor", "$FILENAME" }`

#### [chktex](https://www.nongnu.org/chktex/)

##### About

`latex` semantic linter.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.chktex }
```

##### Defaults

- `filetypes = { "tex" }`
- `command = "chktex"`
- `args = { "-q", "-I0", "-f%l:%c:%d:%k:%m\n" }`

#### [codespell](https://github.com/codespell-project/codespell)

##### About

`codespell` finds common misspellings in text files.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.codespell }
```

##### Defaults

- `filetypes = {}`
- `command = "codespell"`
- `args = { "-" }`

#### [cppcheck](https://github.com/danmar/cppcheck)

##### About

A tool for fast static analysis of `C/C++` code.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.cppcheck }
```

##### Defaults

- `filetypes = { "cpp" , "c" }`
- `command = "cppcheck"`
- `args = { "--enable=warning,style,performance,portability", "--template=gcc", "$FILENAME" }`

#### [credo](https://hexdocs.pm/credo)

##### About

Static analysis for `elixir` files for enforcing code consistency.

- Searches upwards from the buffer to the project root and tries to find the first `.credo.exs` file in case nested credo configs are used.
- When not using a global credo install, the diagnostic can be disable with a conditional checking for the config file with `utils.root_has_file('.credo.exs')`

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.credo }
```

##### Defaults

- `filetypes = { "elixir" }`
- `command = "mix"`
- `args = { "credo", "suggest", "--format", "json", "--read-from-stdin", "$FILENAME" }`

#### [cspell](https://github.com/streetsidesoftware/cspell)

##### About

`cspell` is a spell checker for code.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.cspell }
```

##### Defaults

- `filetypes = {}`
- `command = "cspell"`
- `args = { "stdin" }`

#### [ESLint](https://github.com/eslint/eslint)

##### About

A linter for the `javascript` ecosystem.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.eslint }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }`
- `command = "eslint"`
- `args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" }`

#### [eslint_d](https://github.com/mantoni/eslint_d.js/)

##### About

An absurdly fast linter (and formatter).

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.eslint_d }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }`
- `command = "eslint_d"`
- `args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" }`

#### [flake8](https://github.com/PyCGA/flake8)

##### About

flake8 is a python tool that glues together pycodestyle, pyflakes, mccabe, and third-party plugins to check the style and quality of some python code.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.flake8 }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "flake8"`
- `args = { "--stdin-display-name", "$FILENAME", "-" }`

#### [pylama](https://github.com/klen/pylama)

##### About

Code audit tool for Python.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.pylama }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "pylama"`
- `args = { "--from-stdin", "$FILENAME", "-f", "json" }`

#### [hadolint](https://github.com/hadolint/hadolint)

##### About

A smarter `Dockerfile` linter that helps you build best practice Docker images.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.hadolint }
```

##### Defaults

- `filetypes = { "dockerfile" }`
- `command = "hadolint"`
- `args = { "--no-fail", "--format=json", "$FILENAME" }`

#### [luacheck](https://github.com/mpeterv/luacheck)

##### About

A tool for linting and static analysis of `lua` code.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.luacheck }
```

##### Defaults

- `filetypes = { "lua" }`
- `command = "luacheck"`
- `args = { "--formatter", "plain", "--codes", "--ranges", "--filename", "$FILENAME", "-" }`

#### [markdownlint](https://github.com/DavidAnson/markdownlint) via [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli)

##### About

`markdown` style and syntax checker.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.markdownlint }
```

##### Defaults

- `filetypes = { "markdown" }`
- `command = "markdownlint"`
- `args = { "--stdin" }`

#### [misspell](https://github.com/client9/misspell)

##### About

Checks commonly misspelled English words in source files.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.misspell }
```

##### Defaults

- `filetypes = {}`
- `command = "misspell"`
- `args = { "$FILENAME" }`

#### [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer)

##### About

PHP_CodeSniffer is a script that tokenizes PHP, JavaScript and CSS files to detect violations of a defined coding standard.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.phpcs }
```

##### Defaults

- `filetypes = { "php" }`
- `command = "phpcs"`
- `args = { "--report=json", "-s", "-" }`

#### [phpstan](https://github.com/phpstan/phpstan)

##### About

PHP static analysis tool.

- Requires a valid `phpstan.neon` at root.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.phpstan }
```

##### Defaults

- `filetypes = { "php" }`
- `command = "phpstan"`
- `args = { "analyze", "--error-format", "json", "--no-progress", "$FILENAME" }`

#### [proselint](https://github.com/amperser/proselint)

##### About

An English prose linter.

> proselint places the world’s greatest writers and editors by your side, where they whisper suggestions on how to
> improve your prose.
>
> -- [Proselint](http://proselint.com)

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.proselint }
```

##### Defaults

- `filetypes = { "markdown", "tex" }`
- `command = "proselint"`
- `args = { "--json" }`

#### [psalm](https://psalm.dev)

##### About

A static analysis tool for finding errors in PHP applications

- Requires a valid `psalm.xml` at root.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.psalm }
```

##### Defaults

- `filetypes = { "php" }`
- `command = "psalm"`
- `args = { "--output-format=json", "--no-progress", "$FILENAME" }`

#### [pylint](https://github.com/PyCGA/pylint)

##### About

Pylint is a Python static code analysis tool which looks for programming errors, helps enforcing a coding standard, sniffs for code smells and offers simple refactoring suggestions.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.pylint }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "pylint"`
- `args = {"--from-stdin", "$FILENAME", "-f", "json"}`

#### [qmllint](https://doc-snapshots.qt.io/qt6-dev/qtquick-tools-and-utilities.html#qmllint)

##### About

`qmllint` is a tool shipped with Qt that verifies the syntatic validity of QML
files. It also warns about some QML anti-patterns.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.qmllint }
```

##### Defaults

- `filetypes = { "qml" }`
- `command = "qmllint"`
- `args = { "--no-unqualified-id", "$FILENAME" }`

#### [Rubocop](https://rubocop.org/)

##### About

The Ruby Linter/Formatter that Serves and Protects.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.rubocop }
```

##### Defaults

- `filetypes = { "ruby" }`
- `command = "rubocop"`
- `args = { "-f", "json", "--stdin", "$FILENAME" }`

#### [selene](https://kampfkarren.github.io/selene/)

##### About

Command line tool designed to help write correct and idiomatic `lua` code.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.selene }
```

##### Defaults

- `filetypes = { "lua" }`
- `command = "selene"`
- `args = { "--display-style", "quiet", "-" }`

#### [shellcheck](https://www.shellcheck.net)

##### About

A shell script static analysis tool.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.shellcheck }
```

##### Defaults

- `filetypes = { "sh" }`
- `command = "shellcheck"`
- `args = { "--format", "json1", "--source-path=$DIRNAME", "--external-sources", "-" }`

#### [standardrb](https://github.com/testdouble/standard)

##### About

The Ruby Linter/Formatter that Serves and Protects.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.standardrb }
```

##### Defaults

- `filetypes = { "ruby" }`
- `command = "standardrb"`
- `args = { "--no-fix", "-f", "json", "--stdin", "$FILENAME" }`

#### [statix](https://github.com/nerdypepper/statix)

##### About

Lints and suggestions for the nix programming language.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.statix }
```

##### Defaults

- `filetypes = { "nix" }`
- `command = "statix"`
- `args = { "check", "--stdin", "--format=errfmt" }`

#### [Stylelint](https://github.com/stylelint/stylelint)

##### About

A mighty, modern linter that helps you avoid errors and enforce conventions in your styles.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.stylelint }
```

##### Defaults

- `filetypes = { "scss", "less", "css", "sass" }`
- `command = "stylelint"`
- `args = { "--formatter", "json", "--stdin-filename", "$FILENAME" }`

#### [teal](https://github.com/teal-language/tl)

##### About

Turns `tl check` command into a linter. Works on change.

##### LSP Support

- [neovim](https://github.com/teal-language/teal-language-server)
- [vim](https://github.com/teal-language/vim-teal)

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.teal }
```

##### Defaults

- `filetypes = { "teal" }`
- `command = "tl"`
- `args = { "check", "$FILENAME" }`

#### [vale](https://docs.errata.ai/vale/about)

##### About

Syntax-aware linter for prose built with speed and extensibility in mind.

- `vale` does not include a syntax by itself, so you probably need to grab a
  `vale.ini` (at `"~/.vale.ini"`) and a `StylesPath` (somewhere, pointed from
  `vale.ini`) from [here](https://docs.errata.ai/vale/about#open-source-configurations).

##### Usage

```lua
local sources = {null_ls.builtins.diagnostics.vale}
```

##### Defaults

- `filetypes = { "markdown", "tex" }`
- `command = "vale"`
- `args = { "--no-exit", "--output=JSON", "$FILENAME" }`

#### [vim-vint](https://github.com/Vimjas/vint)

##### About

Linter for `vimscript`.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.vint }
```

##### Defaults

- `filetypes = { "vim" }`
- `command = "vint"`
- `args = { "-s", "-j", "$FILENAME" }`

#### [write-good](https://github.com/btford/write-good)

##### About

English prose linter.

##### Usage

```lua
local sources = {null_ls.builtins.diagnostics.write_good}
```

##### Defaults

- `filetypes = { "markdown" }`
- `command = "write"-good`
- `args = { "--text=$TEXT", "--parse" }`

#### [yamllint](https://github.com/adrienverge/yamllint)

##### About

A linter for YAML files.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.yamllint }
```

##### Defaults

- `filetypes = { "yaml" }`
- `command = "yamllint"`
- `args = { "--format", "parsable", "-" }`

### Diagnostics on save

**NOTE**: These sources **do not run on change**, meaning that the diagnostics
you see will not reflect changes to the buffer until you write the changes to
the disk.

#### [gccdiag](https://gitlab.com/andrejr/gccdiag)

##### About

gccdiag is a wrapper for any C/C++ compiler (gcc, avr-gcc, arm-none-eabi-gcc,
etc) that automatically uses the correct compiler arguments for a file in your
project by parsing the `compile_commands.json` file at the root of your
project.

This builtin will call gccdiag and display the diagnostics like any other LSP
server.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.gccdiag }
```

##### Defaults

- `filetypes = { "c", "cpp" }`
- `command = "gccdiag"`
- `args = { "--default-args", "-S -x $FILEEXT", "-i", "-fdiagnostics-color", "--", "$FILENAME" }`

#### [golangci-lint](https://golangci-lint.run/)

##### About

A Go linter aggregator.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.golangci_lint }
```

##### Defaults

- `filetypes = { "go" }`
- `command = "golangci-lint"`
- `args = { "run", "--fix=false", "--fast", "--out-format=json", "$DIRNAME", "--path-prefix", "$ROOT" }`

#### [revive](https://revive.run/)

##### About

Fast, configurable, extensible, flexible, and beautiful linter for Go.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.revive }
```

##### Defaults

- `filetypes = { "go" }`
- `command = "revive"`
- `args = { "-formatter", "json", "$FILENAME" }`

#### [staticcheck](https://staticcheck.io/)

##### About

Advanced Go linter.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.staticcheck }
```

##### Defaults

- `filetypes = { "go" }`
- `command = "staticcheck"`
- `args = { "-f", "json", "./..." }`

#### [tsc](https://www.typescriptlang.org/docs/handbook/compiler-options.html)

##### About

Parses diagnostics from the TypeScript compiler.

##### Usage

- Diagnostics from this source and `tsserver` are independent. If you have
  `tsserver` configured to show diagnostics, you will see duplicates.

```lua
local sources = { null_ls.builtins.diagnostics.tsc }
```

#### Defaults

- `filetypes = { "typescript", "typescriptreact" }`
- `command = "tsc"`
- `args = { "--pretty", "false", "--noEmit" }`

### Code actions

#### [ESLint](https://github.com/eslint/eslint)

##### About

Injects actions to fix ESLint issues (or ignore broken rules).

##### Usage

```lua
local sources = { null_ls.builtins.code_actions.eslint }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }`
- `command = "eslint"`
- `args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" }`

#### [eslint_d](https://github.com/mantoni/eslint_d.js)

##### About

Injects actions to fix ESLint issues (or ignore broken rules). Like ESLint, but
faster.

##### Usage

```lua
local sources = { null_ls.builtins.code_actions.eslint_d }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }`
- `command = "eslint_d"`
- `args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" }`

#### [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)

##### About

Injects code actions for Git operations at the current cursor position (stage /
preview / reset hunks, blame, etc.).

##### Usage

```lua
local sources = { null_ls.builtins.code_actions.gitsigns }
```

##### Defaults

- `filetypes = {}`

#### gitrebase

##### About

Inject actions to change gitrebase command. (eg. using `squash` instead of `pick`).

##### Usage

```lua
local sources = { null_ls.builtins.code_actions.gitrebase }
```

##### Defaults

- `filetypes = { "gitrebase" }`

#### [proselint](https://github.com/amperser/proselint)

##### About

An English prose linter. Can fix some issues via code actions.

##### Usage

```lua
local source = { null_ls.builtins.code_actions.proselint }
```

##### Defaults

- `filetypes = { "markdown", "tex" }`
- `command = "proselint"`
- `args = { "--json" }`

#### [refactoring.nvim](https://github.com/ThePrimeagen/refactoring.nvim)

##### About

The Refactoring library based off the Refactoring book by Martin Fowler.

##### Usage

- Requires visually selecting the code you want to refactor and calling
  `:'<,'>lua vim.lsp.buf.range_code_action()` (for the default handler) or
  `:'<,'>Telescope lsp_range_code_actions` (for Telescope).

```lua
local sources = { null_ls.builtins.code_actions.refactoring }
```

##### Defaults

- `filetypes = { "go", "javascript", "lua", "python", "typescript" }`

#### [shellcheck](https://www.shellcheck.net)

##### About

Provides actions to disable ShellCheck errors/warnings, either for the
current line or for the entire file.

- Running the action to disable a rule for the current line adds a disable
  directive above the line or appends the rule to an existing disable directive
  for that line.
- Running the action to disable a rule for the current file adds a disable
  directive at the top of the file or appends the rule to an existing file
  disable directive.
- Note: the first non-comment line in a script is not eligible for a line-level
  disable directive.
  See [shellcheck#1877](https://github.com/koalaman/shellcheck/issues/1877).

Consult the [ShellCheck wiki](https://github.com/koalaman/shellcheck/wiki/Ignore)
for more information on disable directives.

##### Usage

```lua
local sources = { null_ls.builtins.code_actions.shellcheck }
```

##### Defaults

- `filetypes = { "sh" }`
- `command = "shellcheck"`
- `args = { "--format", "json1", "--source-path=$DIRNAME", "--external-sources", "-" }`

#### [statix](https://github.com/nerdypepper/statix)

##### About

Lints and suggestions for the nix programming language.

##### Usage

```lua
local sources = { null_ls.builtins.code_actions.statix }
```

##### Defaults

- `filetypes = { "nix" }`
- `command = "statix"`
- `args = { "check", "--stdin", "--format=json" }`

### Hover

#### Dictionary definitions via [dictionaryapi.dev](https://dictionaryapi.dev)

##### About

Shows the first available definition for the current word under the cursor.

##### Usage

- Proof-of-concept for hover functionality. PRs to add more info (e.g. more than
  one definition, part of speech) are welcome.
- Depends on Plenary's `curl` module, which itself depends on having `curl`
  installed and available on your `$PATH`.
- See the Hover section of [the documentation](MAIN.md) for limitations.

```lua
local sources = { null_ls.builtins.hover.dictionary }
```

##### Defaults

- `filetypes = { "txt", "markdown" }`

### Completion

#### Spell

##### About

Spell suggestions completion source.

###### Usage

```lua
local sources = { null_ls.builtins.completion.spell }
```

If you want to disable spell suggestions when `spell` options is not set, you can use the
following snippet:

```lua
runtime_condit
```

#### [vim-vsnip](https://github.com/hrsh7th/vim-vsnip)

##### About

Snippets managed by [vim-vsnip](https://github.com/hrsh7th/vim-vsnip).

##### Usage

```lua
local sources = { null_ls.builtins.completion.vsnip }
```

Registering this source will show available snippets in the completion list, but
vim-vsnip is in charge of expanding them. See [vim-vsnip's documentation for
setup instructions](https://github.com/hrsh7th/vim-vsnip#2-setting).
