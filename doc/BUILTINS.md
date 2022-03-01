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

You can then register sources by passing a `sources` list into your `setup`
function:

```lua
local null_ls = require("null-ls")

-- register any number of sources simultaneously
local sources = {
    null_ls.builtins.formatting.prettier,
    null_ls.builtins.diagnostics.write_good,
    null_ls.builtins.code_actions.gitsigns,
}

null_ls.setup({ sources = sources })
```

To run built-in sources, the command specified below must be available on your
`$PATH` and visible to Neovim. For example, to check if `stylua` is available,
run the following (Vim, not Lua) command:

```vim
" should echo 1 if available (and 0 if not)
:echo executable("stylua")
```

## Configuration

Built-in sources have access to a special method, `with()`, which modifies a
subset of the source's default options. See the descriptions below or the
relevant source file to see the default options passed to each built-in source.

Some options are specific to built-in sources that spawn external commands.

### Filetypes

You can override a source's default filetypes as follows:

```lua
local sources = {
    null_ls.builtins.formatting.prettier.with({
        filetypes = { "html", "json", "yaml", "markdown" },
    }),
}
```

You can also add extra filetypes if your source supports them via a plugin or
configuration:

```lua
local sources = {
    null_ls.builtins.formatting.prettier.with({
        extra_filetypes = { "toml" },
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

null-ls is always inactive in non-file buffers (e.g. file trees and finders) so
theres's no need to specify them.

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

### Environment Variables

You can inject environment variables to the process via utilizing the `env`
option. This option should be in the form of a dictionary. This will extend the
operating system variables.

```lua
local sources = {
    null_ls.builtins.formatting.prettierd.with({
          env = {
            PRETTIERD_DEFAULT_CONFIG = vim.fn.expand "~/.config/nvim/utils/linter-config/.prettierrc.json",
          }
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

- See [CONFIG](CONFIG.md) to learn about the structure of `diagnostics_format`.
- Specifying `diagnostics_format` for a built-in will override your global
  `diagnostics_format` for that source.
- This option is not compatible with `diagnostics_postprocess` (see below).

### Diagnostics postprocess

For advanced customization of diagnostics, you can use the
`diagnostics_postprocess` hook. The hook receives a diagnostic conforming to the
structure described in `:help diagnostic-structure` and runs after the
built-in's generator, so you can use it to change, override, or add data to each
diagnostic.

- Using this option may affect performance when processing a large number of
  diagnostics, since the hook runs once for each diagnostic.
- This option is not compatible with `diagnostics_format` (see above).

```lua
local sources = {
    null_ls.builtins.diagnostics.write_good.with({
        diagnostics_postprocess = function(diagnostic)
            diagnostic.severity = diagnostic.message:find("really")
                and vim.diagnostic.severity["ERROR"]
                or vim.diagnostic.severity["WARN"]
        end,
    }),
}
```

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

### Spawn directory

By default, null-ls spawns commands using the root directory of its client, as
specified in [CONFIG](./CONFIG.md). You can override this on a per-source basis
by setting `cwd` to a function that returns your preferred spawn directory:

```lua
local sources = {
    null_ls.builtins.diagnostics.pylint.with({
        cwd = function(params)
            -- falls back to root if return value is nil
            return params.root:match("my-special-project") and "my-special-cwd"
        end
    }),
}
```

### Timeout

Commands will time out after the timeout specified in [CONFIG](./CONFIG.md). If
a specific command is consistently timing out due to your environment, you can
set a different `timeout`:

```lua
local sources = {
    null_ls.builtins.formatting.prettier.with({
        -- milliseconds
        timeout = 10000
    }),
}
```

## Using local executables

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
manually setting `cwd`, as described above.

You can also choose to override a source's command and specify an absolute path
if the command is not available on your `$PATH`:

```lua
local sources = {
    null_ls.builtins.formatting.prettier.with({
        command = "/path/to/prettier"
    }),
}
```

Another solution is to use the `dynamic_command` option, as described in
[HELPERS](./HELPERS.md). Note that this option can affect performance.

null-ls includes several command resolvers to handle common cases and cache
results to prevent repeated lookups.

For example, the following looks for `prettier` in `node_modules/.bin`, then
tries to find a local Yarn Plug'n'Play install, then tries to find a global
`prettier` executable:

```lua
local command_resolver = require("null-ls.helpers.command_resolver")

local sources = {
    null_ls.builtins.formatting.prettier.with({
        dynamic_command = function(params)
            return command_resolver.from_node_modules(params)
                or command_resolver.from_yarn_pnp(params)
                or vim.fn.executable(params.command) == 1 and params.command
        end,
    }),
}
```

## Conditional sources

### `condition`

Built-ins have access to the `condition` option, which should be a function that
returns a boolean or `nil` indicating whether null-ls should register the
source. `condition` should return `true` (indicating that the source should
continue to run) or a falsy value (indicating that the source should not run
anymore).

```lua
local sources = {
    null_ls.builtins.formatting.stylua.with({
        condition = function(utils)
            return utils.root_has_file({ "stylua.toml", ".stylua.toml" })
        end,
    }),
}
```

For more information, see `condition` in [HELPERS](./HELPERS.md).

Note that if you pass conditional sources into `null_ls.setup`, null-ls will
check the condition at the first opportunity (typically upon entering a named
buffer). After checking, null-ls will not check the same condition again.

### `runtime_condition`

You can force null-ls to check whether a source should run each time by using
the `runtime_condition` option, which is a callback called when generating a
list of sources to run for a given method. If the callback's return value is
falsy, the source does not run.

Be aware that `runtime_condition` runs _every_ time a source can run and thus
should avoid doing anything overly expensive.

```lua
local sources = {
    null_ls.builtins.formatting.pylint.with({
        -- this will run every time the source runs,
        -- so you should prefer caching results if possible
        runtime_condition = function(params)
            return params.root:match("my-monorepo-subdir") ~= nil
        end,
    }),
}
```

### Other cases

null-ls supports dynamic registration, meaning that you can register sources
whenever you want using the methods described in [SOURCES](./SOURCES.md). To
handle advanced registration behavior not covered by the above, you can use
`null_ls.register` with a relevant `autocommand` event listener (or register
sources on demand).

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
- Supports both `textDocument/formatting` and `textDocument/rangeFormatting`.

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

#### [brittany](https://github.com/lspitzner/brittany)

##### About

haskell source code formatter

##### Usage

```lua
local sources = { null_ls.builtins.formatting.brittany }
```

##### Defaults

- `filetypes = { "haskell" }`
- `command = "brittany"`
- `args = {}`

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

#### [buildifier](https://github.com/bazelbuild/buildtools/tree/master/buildifier)

##### About

buildifier is a tool for formatting bazel BUILD and .bzl files with a standard convention.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.buildifier }
```

##### Defaults

- `filetypes = { "bzl" }`
- `command = "buildifier"`
- `args = { "-path=<FILENAME>" }`

#### [cabal-fmt](https://hackage.haskell.org/package/cabal-fmt)

##### About

Format `.cabal` files preserving the original field ordering, and comments.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.cabal_fmt }
```

##### Defaults

- `filetypes = { "cabal" }`
- `command = "cabal-fmt"`
- `args = {}`

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

#### [cljstyle](https://github.com/greglook/cljstyle)

##### About

Formatter for `Clojure` code.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.cljstyle }
```

##### Defaults

- `filetypes = { "clojure" }`
- `command = "cljstyle"`
- `args = { "pipe" }`

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

#### [cue fmt](https://cuelang.org/)

##### About

A CUE language formatter.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.cue_fmt }
```

##### Defaults

- `filetypes = { "cue" }`
- `command = "cue"`
- `args = { "fmt", "$FILENAME" }`

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

#### [deadnix](https://github.com/astro/deadnix)

##### About

Scan Nix files for dead code.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.deadnix }
```

##### Defaults

- `filetypes = { "nix" }`
- `command = "deadnix"`
- `args = { "--output-format=json", "$FILENAME" }`

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

#### [djhtml](https://github.com/rtts/djhtml)

##### About

A pure-Python Django/Jinja template indenter without dependencies.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.djhtml }
```

##### Defaults

- `filetypes = { "django", "jinja.html", "htmldjango" }`
- `command = "djhtml"`
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
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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

#### [fourmolu](https://hackage.haskell.org/package/fourmolu)

##### About

- Fourmolu is a formatter for Haskell source code.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.fouremolu }
```

##### Defaults

- `filetypes = { "haskell" }`
- `command = "fourmolu"`
- `args = {}`

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
- `args = { "-srcdir", "$DIRNAME" }`

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

Reformats Java source code according to Google Java Style.

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

#### [joker](https://github.com/candid82/joker)

##### About

`joker` is a small Clojure interpreter, linter and formatter written in Go.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.joker }
```

##### Defaults

- `filetypes = { "clj" }`
- `command = "joker"`
- `args = { "--format", "-" }`

#### [reorder_python_imports](https://github.com/asottile/reorder_python_imports)

##### About

`python` utility tool for automatically reordering python imports. Like `isort`,
but uses static analysis more.

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

#### [latexindent](https://github.com/cmhughes/latexindent.pl)

##### About

A `perl` script for formatting `LaTeX` files that is generally included in mayor `TeX` distributions.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.latexindent }
```

##### Defaults

- `filetypes = { "tex" }`
- `command = "latexindent"`
- `args = { "-" }`

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

#### [mypy](https://github.com/python/mypy)

##### About

Mypy is an optional static type checker for Python that aims to combine the
benefits of dynamic (or "duck") typing and static typing.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.mypy }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "mypy"`
- `args = function(params) return { "--hide-error-codes", "--hide-error-context", "--no-color-output", "--show-column-numbers", "--show-error-codes", "--no-error-summary", "--no-pretty", "--shadow-file", params.bufname, params.temp_path, params.bufname, } end`

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

`nixfmt` is a formatter for Nix code, intended to apply a uniform style.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.nixfmt }
```

##### Defaults

- `filetypes = { "nix" }`
- `command = "nixfmt"`

#### [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt)

##### About

`nixpkgs-fmt` is a Nix code formatter for nixpkgs.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.nixpkgs_fmt }
```

##### Defaults

- `filetypes = { "nix" }`
- `command = "nixpkgs-fmt"`

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

#### [pgFormatter](https://github.com/darold/pgFormatter)

##### About

PostgreSQL SQL syntax beautifier

##### Usage

```lua
local sources = { null_ls.builtins.formatting.pg_format }
```

##### Defaults

- `filetypes = { "sql", "pgsql" }`
- `command = "pg_format"`

#### [php](https://www.php.net)

##### About

Uses the php command-line tool's built in `-l` flag to check for syntax errors.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.php }
```

##### Defaults

- `filetypes = { "php" }`
- `command = "php"`
- `args = { "-l", "-d", "display_errors=STDERR", "-d", " log_errors=Off" }`

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
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

#### [prettier-standard](https://github.com/sheerun/prettier-standard)

##### About

- Formats with `prettier` (actually `prettierx`) and lints with `eslint` preconfigured with [standard rules](https://standardjs.com/)
- Does not support `textDocument/rangeFormatting`.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.prettier_standard }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact" }`
- `command = "prettier_standard"`
- `args = { "--stdin" }`
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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

#### [protolint](https://https://github.com/yoheimuta/protolint)

##### About

A pluggable linter and fixer to enforce Protocol Buffer style and conventions.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.protolint }
```

##### Defaults

- `filetypes = { "proto" }`
- `command = "protolint"`
- `args = { "--fix", "$FILENAME" }`

#### [qmlformat](https://doc-snapshots.qt.io/qt6-dev/qtquick-tools-and-utilities.html#qmlformat)

##### About

`qmlformat` is a tool that automatically formats QML files according to the QML
Coding Conventions.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.qmlformat }
```

##### Defaults

- `filetypes = { "qml" }`
- `command = "qmlformat"`
- `args = { "-i", "$FILENAME" }`

#### [raco fmt](https://docs.racket-lang.org/fmt/)

##### About

The `fmt` package provides an extensible tool to format Racket code, using an
expressive pretty printer library to compute the optimal layout.

- Requires Racket 8.0 or later
- Install with `raco pkg install fmt`

##### Usage

```lua
local sources = { null_ls.builtins.formatting.raco_fmt }
```

##### Defaults

- `filetypes = { "racket" }`
- `command = "raco"`
- `args = { "fmt", "$FILENAME" }`

#### [remark](https://github.com/remarkjs/remark)

##### About

`remark` is an extensive and complex Markdown formatter/prettifier. For this integration to work specifically, you need to install [the `remark-cli` tool](https://github.com/remarkjs/remark/tree/main/packages/remark-cli).

##### Usage

```lua
local sources = { null_ls.builtins.formatting.remark }
```

##### Defaults

- `filetypes = { "markdown" }`
- `command = "remark"`
- `args = { "--no-color", "--silent" }`

#### [rescript](https://rescript-lang.org/)

##### About

The ReScript format builtin.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.rescript }
```

##### Defaults

- `filetypes = { "rescript" }`
- `command = "rescript"`
- `args = { "format", "-stdin", "." .. vim.fn.fnamemodify(params.bufname, ":e")}`
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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

- `--edition` defaults to `2015`. To set a different edition, use `extra_args`.
- See [the
  wiki](https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Source-specific-Configuration#rustfmt)
  for other workarounds.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.rustfmt }
```

##### Defaults

- `filetypes = { "rust" }`
- `command = "rustfmt"`
- `args = { "--emit=stdout" }`

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
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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

The `sqlformat` command-line tool can reformat SQL files according to specified
options.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.sqlformat }
```

##### Defaults

- `filetypes = { "sql" }`
- `command = "sqlformat"`
- `args = { "-" }`

#### [standardjs](https://standardjs.com/)

##### About

- JavaScript Standard Style, a no-configuration automatic code formatter that
  just works.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.standardjs }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact" }`
- `command = "standard"`
- `args = { "--stdin" }`
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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
- Supports `textDocument/formatting`.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.styler }
```

##### Defaults

- `filetypes = { "r", "rmd" }`
- `command = "R"`
- `args`
  - For `r` filetype: `{ "--slave", "--no-restore", "--no-save", "-e", 'con=file("stdin");output=styler::style_text(readLines(con));close(con);print(output, colored=FALSE)' }`
  - For `rmd` filetype: `string.format([[options(styler.quiet = TRUE) con = file("stdin") temp = tempfile("styler",fileext = ".%s") writeLines(readLines(con), temp) styler::style_file(temp) cat(paste0(readLines(temp), collapse = '\n')) close(con) ]], params.ft)`

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

#### [terrafmt](https://github.com/katbyte/terrafmt)

##### About

The `terrafmt` command formats `terraform` blocks embedded on `markdown` files.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.terrafmt }
```

##### Defaults

- `filetypes = { "markdown" }`
- `command = "terrafmt"`
- `args = { "fmt", "$FILENAME" }`

#### [terraform_fmt](https://www.terraform.io/docs/cli/commands/fmt.html)

##### About

The `terraform-fmt` command rewrites `terraform` configuration files to a
canonical format and style.

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

#### [xmllint](http://xmlsoft.org/xmllint.html)

##### About

Despite the name, `xmllint` can be used to format XML files as well as lint
them, and that's the mode this builtin is using.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.xmllint }
```

##### Defaults

- `filetypes = { "xml" }`
- `command = "xmllint"`
- `args = { "--format", "-" }`

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

#### [nimpretty](https://nim-lang.org/docs/tools.html)

##### About

`nimpretty` is a `Nim` source code beautifier, to format code according to the official style guide.

##### Usage

```lua
local sources = { null_ls.builtins.formatting.nimpretty }
```

##### Defaults

- `filetypes = { "nim" }`
- `command = "nimpretty"`
- `args = { "$FILENAME" }`

#### [ptop](https://www.freepascal.org/tools/ptop.html)

##### About

The FPC Pascal configurable source beautifier. Name means "Pascal-TO-Pascal".

##### Usage

```lua
local sources = { null_ls.builtins.formatting.ptop }
```

##### Defaults

- `filetypes = { "pascal" }`
- `command = "ptop"`
- `args = { "$FILENAME", "$FILENAME" }`

### Diagnostics

#### [actionlint](https://github.com/rhysd/actionlint)

##### About

Actionlint is a static checker for GitHub Actions workflow files.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.actionlint }
```

##### Defaults

- `filetypes = { "yaml" }`
- `command = "actionlint"`
- `args = { "-no-color", "-format", "{{json .}}", "-" }`

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

#### [checkmake](https://github.com/mrtazz/checkmake)

##### About

`make` linter.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.checkmake }
```

##### Defaults

- `filetypes = { "make" }`
- `command = "checkmake"`
- `args = { "--format='{{.LineNumber}}:{{.Rule}}:{{.Violation}}'", "$FILENAME" }`

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
- `args = { "-q", "-f%l:%c:%d:%k:%n:%m\n" }`

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

- Searches upwards from the buffer to the project root and tries to find the
  first `.credo.exs` file in case the project has nested credo configs.
- When not using a global credo install, the diagnostic can be disable with a
  conditional checking for the config file with
  `utils.root_has_file('.credo.exs')`

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
- `args = function(params) return { "--language-id", params.ft, "stdin" } end,`

#### [cue fmt](https://github.com/cue-lang/cue)

##### About

Report on formatting errors in `.cue` language files.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.cue_fmt }
```

##### Defaults

- `filetypes = { "cue" }`
- `command = "cue"`
- `args = { "fmt", "$FILENAME" }`

#### [curlylint](https://www.curlylint.org/)

##### About

Experimental HTML templates linting for Jinja, Nunjucks, Django templates, Twig, Liquid

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.curlylint }
```

##### Defaults

- `filetypes = { "jinja.html", "htmldjango" }`
- `command = "curlylint"`
- `args = { "--quiet", "-", "--format", "json", "--stdin-filepath", "$FILENAME" }`

#### [editorconfig-checker](https://github.com/editorconfig-checker/editorconfig-checker)

##### About

A tool to verify that your files are in harmony with your .editorconfig

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.editorconfig_checker }
```

##### Defaults

- `filetypes = {}`
- `command = "ec"`
- `args = { "-no-color", "$FILENAME" }`

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
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

#### [flake8](https://github.com/PyCQA/flake8)

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

#### [gitlint](https://jorisroovers.com/gitlint/)

##### About

Linter for git commit messages

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.gitlint }
```

##### Defaults

- `filetypes = { "gitcommit" }`
- `command = "gitlint"`
- `args = { "--msg-filename", "$FILENAME" }`

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

#### [jsonlint](https://github.com/zaach/jsonlint)

##### About

A pure JavaScript version of the service provided at jsonlint.com.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.jsonlint }
```

##### Defaults

- `filetypes = { "json" }`
- `command = "jsonlint"`
- `args = { "--compact" }`

#### [luacheck](https://github.com/lunarmodules/luacheck)

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

#### [mdl](https://github.com/markdownlint/markdownlint)

##### About

A tool to check markdown files and flag style issues.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.mdl }
```

##### Defaults

- `filetypes = { "markdown" }`
- `command = "mdl"`
- `args = { "--json" }`

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

#### [phpmd](https://github.com/phpmd/phpmd/)

##### About

Runs PHP Mess Detector against PHP files.

##### Usage

```lua
local sources = {
  null_ls.builtins.diagnostics.phpmd.with({
    extra_args = { "phpmd.xml" }
  }),
}
```

Note that `extra_args` is required, and allows you so specify the
[ruleset](https://phpmd.org/documentation/index.html#using-multiple-rule-sets).

##### Defaults

- `filetypes = { "php" }`
- `command = "phpmd"`
- `args = { '--ignore-violations on exit', '-', 'json' }`

##### Additional Notes

Note that PHPMD version 2.11.1 requires updating with the latest version of
[PHP_Depend](https://github.com/pdepend/pdepend):

```bash
composer update pdepend/pdepend:dev-master
```

- Bug: https://github.com/phpmd/phpmd/issues/941
- Fix: https://github.com/pdepend/pdepend/pull/593

Later versions of PHPMD should already have the fix.

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

#### [protoc-gen-lint](https://github.com/ckaznocha/protoc-gen-lint)

##### About

A plug-in for Google's Protocol Buffers (protobufs) compiler to lint .proto files for style violations.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.protoc_gen_lint }
```

##### Defaults

- `filetypes = { "proto" }`
- `command = "protoc"`
- `args = { "--line_out", "$FILENAME", "-I", "/tmp", "$FILENAME"}`

#### [protolint](https://https://github.com/yoheimuta/protolint)

##### About

A pluggable linter and fixer to enforce Protocol Buffer style and conventions.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.protolint }
```

##### Defaults

- `filetypes = { "proto" }`
- `command = "protolint"`
- `args = { "--reporter", "json", "$FILENAME" }`

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

#### [pydocstyle](https://www.pydocstyle.org)

##### About

pydocstyle is a static analysis tool for checking compliance with Python docstring conventions.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.pydocstyle }
```

The `pydocstyle` config discovery ignores the CWD and searches
configuration starting at the file location. Since null-ls has to
use a temporary file to call `pydocstyle` it won't find the project
configuration.

A workaround is to pass the config-filename to use:

```lua
local sources = {
  null_ls.builtins.diagnostics.pydocstyle.with({
    extra_args = { "--config=$ROOT/setup.cfg" }
  }),
}
```

##### Defaults

- `filetypes = { "python" }`
- `command = "pydocstyle"`
- `args = { "$FILENAME" }`

#### [pylint](https://github.com/PyCQA/pylint)

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

#### [rpmspec](https://rpm.org/)

##### About

Command line tool to parse RPM spec files.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.rpmspec }
```

##### Defaults

- `filetypes = { "spec" }`
- `command = "rpmspec"`
- `args = { "-P", "$FILENAME" }`

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

#### [standardjs](https://standardjs.com/)

##### About

JavaScript style guide, linter, and formatter.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.standardjs }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact" }`
- `command = "standard"`
- `args = { "--stdin" }`
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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

#### [textlint](https://github.com/textlint/textlint)

##### About

The pluggable linting tool for text and markdown.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.textlint }
```

##### Defaults

- `filetypes = {}`
- `command = "textlint"`
- `args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" }`

#### `trail_space`

##### About

Uses inbuilt lua code to detect lines with trailing whitespace and show a diagnostic warning on each line where it's present.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.trail_space }
```

By default this source applies to all filetypes. You may wish to customize it with some `disabled_filetypes` if you have any existing `null_ls` sources or LSP providers which highlight trailing space for some filetypes already, to avoid duplicates, or if you have filetypes where you don't want to highlight whitespace. For example, to disable this source for `gitcommit` files:

```
local sources = { null_ls.builtins.diagnostics.trail_space.with({ disabled_filetypes = { "gitcommit" }})
```

##### Defaults

- `filetypes = {}`

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

#### [vulture](https://github.com/jendrikseipp/vulture)

##### About

Vulture finds unused code in Python programs.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.vulture }
```

##### Defaults

- `filetypes = { "python" }`
- `command = "vulture"`
- `args = { "$FILENAME" }`

#### [write-good](https://github.com/btford/write-good)

##### About

English prose linter.

##### Usage

```lua
local sources = {null_ls.builtins.diagnostics.write_good}
```

##### Defaults

- `filetypes = { "markdown" }`
- `command = "write-good"`
- `args = { "--text=$TEXT", "--parse" }`

#### [XO](https://github.com/xojs/xo)

##### About

❤️ JavaScript/TypeScript linter (ESLint wrapper) with great defaults

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.xo }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }`
- `command = "xo"`
- `args = { "--reporter", "json", "--stdin", "--stdin-filename", "$FILENAME" }`

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

#### [zsh](https://www.zsh.org/)

##### About

Uses zsh's own `-n` option to evaluate, but not execute, zsh scripts. Effectively, this acts somewhat like a linter, although it only really checks for serious errors - and will likely only show the first error.

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.zsh }
```

##### Defaults

- `filetypes = { "zsh" }`
- `command = "zsh"`
- `args = { "-n", "$FILENAME" }`

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

- Supports project-level diagnostics.

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

- Supports project-level diagnostics.

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

- Supports project-level diagnostics.
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
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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
- `dynamic_command = require("null-ls.helpers.command_resolver").from_node_modules`

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
local sources = { null_ls.builtins.code_actions.proselint }
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

#### [XO](https://github.com/xojs/xo)

##### About

❤️ JavaScript/TypeScript linter (ESLint wrapper) with great defaults

##### Usage

```lua
local sources = { null_ls.builtins.diagnostics.xo }
```

##### Defaults

- `filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }`
- `command = "xo"`
- `args = { "--reporter", "json", "--stdin", "--stdin-filename", "$FILENAME" }`

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

- `filetypes = { "text", "markdown" }`

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

#### [luasnip](https://github.com/L3MON4D3/LuaSnip)

##### About

Snippet Engine For Neovim written in lua.

##### Usage

```lua
local sources = { null_ls.builtins.completion.luasnip }
```

Registering this source will show available snippets in the completion list, but
luasnip is in charge of expanding them. Consult luasnip's documentation
[here](https://github.com/L3MON4D3/LuaSnip#keymaps) to set up keymaps for
expansion and jumping.

#### [astyle](http://astyle.sourceforge.net/)

##### About

Artistic Style is a source code indenter, formatter, and beautifier for the C, C++, C++/CLI, Objective‑C, C# and Java programming languages.

This formatter works well for [Arduino](https://www.arduino.cc/) project files and it is the same formatting files in the Arduino IDE

##### Usage

```lua
local sources = { null_ls.builtins.formatting.astyle }
```

##### Defaults

- `filetypes = { "arduino", "c", "cpp", "cs", "java" }`
