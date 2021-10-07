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
source's default options. For example, you can alter a source's file types as
follows:

```lua
local sources = {
    null_ls.builtins.formatting.prettier.with({
        filetypes = { "html", "json", "yaml", "markdown" },
    }),
}
```

See the descriptions below or the relevant `builtins` source file to see the
default options passed to each built-in source.

Note that setting `filetypes = {}` will enable the source for all filetypes,
which isn't recommended for most sources.

You can override `args` using `with({ args = your_args })`, but if you want to
add more flags, you should use `extra_args` instead:

```lua
local sources = {
    null_ls.builtins.formatting.shfmt.with({
        extra_args = { "-i", "2", "-ci" }
      })
  }
```

Note that environment variables and `~` aren't expanded in arguments. As a
workaround, you can use `vim.fn.expand`:

```lua
local sources = {
    null_ls.builtins.formatting.stylua.with({
        extra_args = { "--config-path", vim.fn.expand("~/.config/stylua.toml") },
    }),
}
```

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

#### [dfmt](https://github.com/dlang-community/dfmt)

##### About

Formatter for `D` source code

##### Usage

```lua
local sources = { null_ls.builtins.formatting.dfmt }
```

##### Defaults

- `filetypes = { "d" }`
- `command = "dfmt"`
- `args = {}`

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

#### [deno formatter](https://deno.land/manual/tools/formatter)

##### About

Use [deno](https://deno.land) to format TypeScript and JavaScript code

##### Usage

```lua
local sources = { null_ls.builtins.formatting.deno_fmt }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }`
- `command = "deno"`
- `args = { "fmt", "-"}`

#### [elm-format](https://github.com/avh4/elm-format)

##### About

`elm-format` formats Elm source code according to a standard set of rules based
on the [official Elm Style Guide](https://elm-lang.org/docs/style-guide)

##### Usage

```lua
local sources = { null_ls.builtins.formatting.elm_format }
```

##### Defaults

- `filetypes = { "elm" }`
- `command = "elm-format"`
- `args = { "--stdin", "--elm-version=0.19" }`

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

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" }`
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

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" }`
- `command = "eslint_d"`
- `args = { "--fix-to-stdout", "--stdin", "--stdin-filepath", "$FILENAME" }`

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

#### [fprettify](https://github.com/pseewald/fprettify)

##### About

`fprettify` is an auto-formatter for modern Fortran code that imposes strict whitespace formattin.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.fprettify }
```

##### Defaults

- `filetypes = { "fortran" }`
- `command = "fprettify"`
- `args = { "--silent" }`

#### [golines](https://pkg.go.dev/github.com/segmentio/golines)

##### About

Applies a base formatter (eg. `goimports` or `gofmt`), then shorten long lines of code

##### Usage

```lua
local sources = { null_ls.builtins.formatting.golines }
```

##### Defaults

- `filetypes = { "go" }`
- `command = "golines"`
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

#### [isort](https://github.com/PyCQA/isort)

##### About

`python` utility / library to sort imports alphabetically, and automatically
separated into sections and by type.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.isort }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "isort"`
- `args = { "--stdout", "--profile", "black", "-" }`

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

#### [prettier](https://github.com/prettier/prettier)

##### About

- Supports both `textDocument/formatting` and `textDocument/rangeFormatting`
- May not work on some filetypes.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.prettier }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "css", "scss", "html", "json", "yaml", "markdown" }`
- `command = "prettier"`
- `args = { "--stdin-filepath", "$FILENAME" }`

#### [prettier_d_slim](https://github.com/mikew/prettier_d_slim)

##### About

- A faster version of `prettier` that doesn't seem to work well on
  non-JavaScript filetypes.
- Supports both `textDocument/formatting` and `textDocument/rangeFormatting`
- May not work on some filetypes.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.prettier_d_slim }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" }`
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

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "css", "scss", "html", "json", "yaml", "markdown" }`
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
- args = { "--format", "json1", "-" },

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

#### [shfmt](https://github.com/mvdan/sh)

##### About

A `shell` parser, formatter, and interpreter with `bash` support

##### Usage

```lua
local sources = { null_ls.builtins.formatting.shfmt }
```

##### Defaults

- `filetypes = { "sh" }`
- `command = "shfmt"`
- `args = {}`

#### [shellharden](https://github.com/anordal/shellharden)

##### About

Hardens shell scripts by quoting variables, replacing `` `function_call` `` with `$(function_call)`, and more

##### Usage

```lua
local sources = { null_ls.builtins.formatting.shellharden }
```

##### Defaults

- `filetypes = { "sh" }`
- `command = "shellharden"`
- `args = { "--transform", "$FILENAME" }`

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

if you want to use this with specific filetypes you can set using `with`

```lua
local sources = { null_ls.builtins.formatting.trim_newlines.with({
    filetypes = { "lua", "c", "cpp }
}) }
```

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

if you want to use this with specific filetypes you can set using `with`

```lua
local sources = { null_ls.builtins.formatting.trim_whitespace.with({
    filetypes = { "lua", "c", "cpp }
}) }
```

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

##### Usage

```lua
local sources = { null_ls.builtins.formatting.yapf }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "yapf"`
- `args = { "--quiet" }`

#### [autopep8](https://github.com/hhatto/autopep8)

##### About

Formatter for `python` files

##### Usage

```lua
local sources = { null_ls.builtins.formatting.autopep8 }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "autopep8"`
- `args = { "-" }`

#### [php-cs-fixer](https://github.com/FriendsOfPhp/PHP-CS-Fixer)

##### About

Formatter for `php` files

##### Usage

```lua
local sources = { null_ls.builtins.formatting.phpcsfixer }
```

##### Defaults

- `filetypes = { "php" }`
- `command = "php-cs-fixer"`
- `args = { '--no-interaction', '--quiet', 'fix', "$FILENAME" }`

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

### Diagnostics

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

`codespell` fix common misspellings in text files.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.codespell }
```

##### Defaults

- `filetypes = {}`
- `command = "codespell"`
- `args = { "-" }`

#### [ESLint](https://github.com/eslint/eslint)

##### About

A linter for the `javascript` ecosystem.

- Note that the `null-ls` builtin requires your `eslint` executable to be
  available on your `$PATH`.
- To use local (project) executables, use the
  integration in
  [nvim-lsp-ts-utils](https://github.com/jose-elias-alvarez/nvim-lsp-ts-utils).

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.eslint }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" }`
- `command = "eslint"`
- `args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" }`

#### [eslint_d](https://github.com/mantoni/eslint_d.js/)

##### About

An absurdly fast linter (and formatter).

- See the notes re: ESLint above.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.eslint_d }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" }`
- `command = "eslint"`
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

#### [vale](https://docs.errata.ai/vale/about)

##### About

Syntax-aware linter for prose built with speed and extensibility in mind.

##### Usage

- `vale` does not include a syntax by itself, so you probably need to grab a
  `vale.ini` (at `"~/.vale.ini"`) and a `StylesPath` (somewhere, pointed from
  `vale.ini`) from [here](https://docs.errata.ai/vale/about#open-source-configurations).

```lua
local sources = {null_ls.builtins.diagnostics.vale}
```

##### Defaults

- `filetypes = { "markdown", "tex" }`
- `command = "vale"`
- `args = { "--no-exit", "--output=JSON", "$FILENAME" }`

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

#### [misspell](https://github.com/client9/misspell)

##### About

Correct commonly misspelled English words in source files

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.misspell }
```

##### Defaults

- `filetypes = {}`
- `command = "misspell"`
- `args = { "$FILENAME" }`

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

#### [phpstan](https://github.com/phpstan/phpstan)

##### About

PHP Static Analysis Tool

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.phpstan }
```

##### Defaults

- `filetypes = { "php" }`
- `command = "phpstan"`
- `args = { "analyze", "--error-format", "json", "--no-progress", "$FILENAME" }`

##### Requirements

A valid `phpstan.neon` at root.

#### [psalm](https://psalm.dev)

##### About

A static analysis tool for finding errors in PHP applications

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.psalm }
```

##### Defaults

- `filetypes = { "php" }`
- `command = "psalm"`
- `args = { "--output-format=json", "--no-progress", "$FILENAME" }`

##### Requirements

A valid `psalm.xml` at root.

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
