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

isort is a Python utility / library to sort imports alphabetically, and automatically separated into sections and by type.

- Filetypes: `{ "python" }`
- Command: `isort`
- Arguments: `{ "--stdout", "--profile", "black", "-" }`

#### [json.tool](https://docs.python.org/3/library/json.html#module-json.tool)

```lua
local sources = {null_ls.builtins.formatting.json_tool}
```

The json.tool module provides a simple command line interface to validate and pretty-print JSON objects.

- Filetypes: `{ "json" }`
- Command: `python`
- Arguments: `{ "-m", "json.tool" }`

#### [LuaFormatter](https://github.com/Koihik/LuaFormatter)

A flexible but slow Lua formatter. Not recommended for formatting on save.

```lua
local sources = {null_ls.builtins.formatting.lua_format}
```

- Filetypes: `{ "lua" }`
- Command: `lua-format`
- Arguments: `{ "-i" }`

#### [Mix](https://hexdocs.pm/mix/1.12/Mix.html)

```lua
local sources = {null_ls.builtins.formatting.mix}
```

Mix is a build tool that provides tasks for creating, compiling, and testing Elixir projects, managing its dependencies, and more.

- Filetypes: `{ "elixir" }`
- Command: `mix`
- Arguments: `{ "format", "-" }`

#### [Nginx Beautifier](https://github.com/vasilevich/nginxbeautifier)

```lua
local sources = {null_ls.builtins.formatting.nginx_beautifier}
```

This Javascript script beautifies and formats Nginx configuration files.

- Filetypes: `{ "nginx" }`
- Command: `nginxbeautifier`
- Arguments: `{ "-i" }`

#### [perltidy](http://perltidy.sourceforge.net/)

```lua
local sources = {null_ls.builtins.formatting.perltidy}
```

Perltidy is a Perl script which indents and reformats Perl scripts to make them easier to read. If you write Perl scripts, or spend much time reading them, you will probably find it useful.

- Filetypes: `{ "perl" }`
- Command: `perltidy`
- Arguments: `{ "-q" }`

#### [phpcbf](https://github.com/squizlabs/PHP_CodeSniffer)

```lua
local sources = {null_ls.builtins.formatting.phpcbf}
```

Tokenizes PHP files and detects violations of a defined set of coding standards.

- Filetypes: `{ "php" }`
- Command: `phpcbf`
- Arguments: `{ "--standard=PSR12", "-" }`

#### [Prettier](https://github.com/prettier/prettier)

Supports both `textDocument/formatting` and `textDocument/rangeFormatting`
(may not work on some filetypes).

```lua
local sources = {null_ls.builtins.formatting.prettier}
```

- Filetypes: `{ "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "css", "html", "json", "yaml", "markdown" }`
- Command: `prettier`
- Arguments: `{ "--stdin-filepath", "$FILENAME" }`

#### [prettier_d_slim](https://github.com/mikew/prettier_d_slim)

A faster version of Prettier that doesn't seem to work well on non-JavaScript
filetypes. Supports both `textDocument/formatting` and `textDocument/rangeFormatting`
(may not work on some filetypes).

```lua
local sources = {null_ls.builtins.formatting.prettier_d_slim}
```

- Filetypes: `{ "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }`
- Command: `prettier_d_slim`
- Arguments: ` { "--stdin", "--stdin-filepath", "$FILENAME" }`

#### [prettierd](https://github.com/fsouza/prettierd)

Another "Prettier, but faster" formatter, with better support for non-JavaScript
filetypes.

- Filetypes: `{ "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "css", "html", "json", "yaml", "markdown" }`
- Command: `prettierd`
- Arguments: `{ "$FILENAME" }`

#### [formatR](https://github.com/yihui/formatR)

```lua
local sources = {null_ls.builtins.formatting.format_r}
```

Format R code automatically.

- Filetypes: `{ "r", "rmd" }`
- Command: `R`
- Arguments: `{ 
  "--slave",
  "--no-restore",
  "--no-save",
  '-e "formatR::tidy_source(text=readr::read_file(file(\\"stdin\\")), arrow=FALSE)"'
  }`

#### [Rufo](https://github.com/ruby-formatter/rufo)

```lua
local sources = {null_ls.builtins.formatting.rufo}
```

Rufo is as an opinionated ruby formatter.

- Filetypes: `{ "ruby" }`
- Command: `rufo`
- Arguments: `{ "-x" }`

#### [rustfmt](https://github.com/rust-lang/rustfmt)

```lua
local sources = {null_ls.builtins.formatting.rustfmt}
```

A tool for formatting Rust code according to style guidelines.

- Filetypes: `{ "rust" }`
- Command: `rustfmt`
- Arguments: `{ "--emit=stdout", "--edition=2018" }`

#### [sqlformat](https://manpages.ubuntu.com/manpages/xenial/man1/sqlformat.1.html)

```lua
local sources = {null_ls.builtins.formatting.sqlformat}
```

The  `sqlformat` command-line tool can be used to reformat SQL file according to specified options.

- Filetypes: `{ "sql" }`
- Command: `sqlformat`
- Arguments: `{ "--reindent", "-" }`

#### [scalafmt](https://github.com/scalameta/scalafmt)

```lua
local sources = {null_ls.builtins.formatting.scalafmt}
```

Code formatter for Scala

- Filetypes: `{ "scala" }`
- Command: `scalafmt`
- Arguments: `{ "--stdin" }`

#### [shfmt](https://github.com/mvdan/sh)

```lua
local sources = {null_ls.builtins.formatting.shfmt}
```

A shell parser, formatter, and interpreter with bash support

- Filetypes: `{ "sh" }`
- Command: `shfmt`
- Arguments: `{}`

#### [StyLua](https://github.com/JohnnyMorganz/StyLua)

```lua
local sources = {null_ls.builtins.formatting.stylua}
```

A fast and opinionated Lua formatter written in Rust. Highly recommended!

- Filetypes: `{ "lua" }`
- Command: `stylua`
- Arguments: `{ "-" }`

#### [swfitformat](https://github.com/nicklockwood/SwiftFormat)

```lua
local sources = {null_ls.builtins.formatting.swiftformat}
```

SwiftFormat is a code library and command-line tool for reformatting Swift code on macOS or Linux.

- Filetypes: `{ "swift" }`
- Command: `swiftformat`
- Arguments: `{}`

#### [terraform_fmt](https://www.terraform.io/docs/cli/commands/fmt.html)

```lua
local sources = {null_ls.builtins.formatting.terraform_fmt}
```

The terraform fmt command is used to rewrite Terraform configuration files to a canonical format and style. 

- Filetypes: `{ "tf", "hcl" }`
- Command: `terraform`
- Arguments: `{ "fmt", "-" }`

#### trim_whitespace

A simple wrapper around `awk` to remove trailing whitespace.

```lua
local sources = { null_ls.builtins.formatting.trim_whitespace.with({ filetypes = { ... } }) }
```

- Filetypes: none (must specify in `with()`, as above)
- Command: `awk`
- Arguments: `{ '{ sub(/[ \t]+$/, ""); print }' }`

#### [uncrustify](https://github.com/uncrustify/uncrustify)

```lua
local sources = {null_ls.builtins.formatting.uncrustify}
```

A source code beautifier for C, C++, C#, ObjectiveC, D, Java, Pawn and VALA.

- Filetypes: `{ "c", "cpp", "cs", "java" }`
- Command: `uncrustify`
- Arguments: `{ "-q", "-l <LANG>" }`

#### [yapf](https://github.com/google/yapf)

```lua
local sources = {null_ls.builtins.formatting.yapf}
```

A formatter for Python files

- Filetypes: `{ "python" }`
- Command: `yapf`
- Arguments: `{ "--quiet" }`

### Diagnostics

#### [ChkTeX](https://www.nongnu.org/chktex/)

A LaTeX semantic linter.

```lua
local sources = {null_ls.builtins.diagnostics.chktex}
```

- Filetypes: `{ "tex" }`
- Command: `chktex`
- Arguments: `{ "-q", "-I0", "-f%l:%c:%d:%k:%m\n" }`

#### [Clang-Tidy](https://clang.llvm.org/extra/clang-tidy/)

A clang-based C++ linter tool.

```lua
local sources = {null_ls.builtins.diagnostics.clang_tidy}
```

- Filetypes: `{ "c", "cpp" }`
- Command: `clang-tidy`
- Arguments: `{ "--quiet", "$FILENAME" }`

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

- Filetypes: `{ "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }`
- Command: `eslint`
- Arguments: `{ "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" }`

#### [Flake8](https://github.com/pycqa/flake8)

flake8 is a python tool that glues together pycodestyle, pyflakes, mccabe, and third-party plugins to check the style and quality of some python code. 

```lua
local sources = {null_ls.builtins.diagnostics.flake8}
```

- Filetypes: `{ "python" }`
- Command: `flake8`
- Arguments: `{ "--stdin-display-name", "$FILENAME", "-" }`

#### [Golangci-lint](https://golangci-lint.run/)

A Go linters aggregator

```lua
local sources = {null_ls.builtins.diagnostics.golangci_lint}
```

- Filetypes: `{ "go" }`
- Command: `golangci`
- Arguments: `{ "run", "--fix=false", "--out-format", "tab", "$FILENAME" }`

#### [hadolint](https://github.com/hadolint/hadolint)

A smarter Dockerfile linter that helps you build best practice Docker images.

```lua
local sources = {null_ls.builtins.diagnostics.hadolint}
```

- Filetypes: `{ "dockerfile" }`
- Command: `hadolint`
- Arguments: `{ "--no-fail", "--format=json", "$FILENAME" }`

#### [markdownlint](https://github.com/DavidAnson/markdownlint) via [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli)

Markdown style and syntax checker.

```lua
local sources = {null_ls.builtins.diagnostics.markdownlint}
```

- Filetypes: `{ "markdown" }`
- Command: `markdownlint`
- Arguments: `{ "--stdin" }`

#### [misspell](https://github.com/client9/misspell)

Correct commonly misspelled English words in source files

```lua
local sources = {null_ls.builtins.diagnostics.misspell}
```

- Filetypes: `{ "*" }`
- Command: `misspell`
- Arguments: `{ "$FILENAME" }`

#### [selene](https://github.com/Kampfkarren/selene)

A blazing-fast modern Lua linter written in Rust

```lua
local sources = {null_ls.builtins.diagnostics.selene}
```

- Filetypes: `{ "lua" }`
- Command: `selene`
- Arguments: `{ "--display_style", "quiet", "-" }`

#### [shellcheck](https://github.com/koalaman/shellcheck)

ShellCheck, a static analysis tool for shell scripts

```lua
local sources = {null_ls.builtins.diagnostics.shellcheck}
```

- Filetypes: `{ "sh" }`
- Command: `shellcheck`
- Arguments: `{ "--format", "json", "-" }`

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

#### [vim-vint](https://github.com/Vimjas/vint)

Linter for vimscript.

```lua
local sources = {null_ls.builtins.diagnostics.vint}
```

- Filetypes: `{ "vim" }`
- Command: `vint`
- Arguments: `{ "-s", "-j", "$FILENAME" }`

#### [write-good](https://github.com/btford/write-good)

English prose linter.

```lua
local sources = {null_ls.builtins.diagnostics.write_good}
```

- Filetypes: `{ "markdown" }`
- Command: `write-good`
- Arguments: `{ "--text=$TEXT", "--parse" }`


