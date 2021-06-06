# Helpers

null-ls provides helpers to streamline the process of transforming command line
output into LSP diagnostics, code actions, or formatting.

The plugin exports available helpers under `null_ls.helpers`:

```lua
local null_ls = require("null-ls")

null_ls.helpers.generator_factory(my_opts)
```

Please see the [built-in files](../lua/null-ls/builtins/) for examples of how to
use helpers to create generators.

## generator_factory

`generator_factory` is a general-purpose helper that returns a generator which
will spawns a command with the given options, optionally transforms its output,
then calls an `on_output` callback with the command's output. It accepts one
argument, `opts`, which is a table with the following structure.

All options are **required** unless specified otherwise.

```lua
local null_ls = require("null-ls")

null_ls.helpers.generator_factory({
    command, -- string
    args, -- table (optional)
    on_output, -- function
    format, -- "raw", "line", "json", or "json_raw" (optional)
    to_stderr, -- boolean (optional)
    to_stdin, -- boolean (optional)
    ignore_errors, -- boolean (optional)
    check_exit_code, -- function (optional)
    timeout, -- number (optional)
    to_temp_file, -- boolean (optional)
})
```

null-ls validates each option using `vim.validate` when the generator runs for
the first time.

### command

A string containing the command that the generator will spawn.

### args

A table containing the arguments passed when spawning the command. Defaults to `{}`.

null-ls will transform the following special arguments before spawning:

- `$FILENAME`: replaced with the current buffer's full path

- `$TEXT`: replaced with the current buffer's content

### on_output

A callback function that receives a `params` object, which contains information
about the current buffer and editor state (see _Generators_ in
[MAIN](MAIN.md) for details).

Generators created by `generator_factory` have access to an extra parameter,
`params.output`, which contains the output from the spawned command. The
structure of `params.output` depends on `format`, described below.

### format

Specifies the format used to transform output before passing it to `on_output`.
Supports the following options:

- `"raw"`: passes command output directly as `params.output` (string) and error
  output as `params.err` (string).

  This format will call `on_output(params, done)`, where `done()` is a callback that
  `on_output` must call with its results (see _Generators_ in
  [MAIN](MAIN.md) for details).

- `nil`: same as `raw`, but does not receive error output. Instead, error output
  will cause the generator to throw an error, unless `ignore_errors` is also
  enabled (see below).

- `"line"`: splits generator output into lines and calls `on_output(line, params)`
  once for each line, where `line` is a string.

  `on_output` should return `nil` or an object that matches the structure
  expected for its method, **not** a list of results (see _Generators_ in
  [MAIN](MAIN.md) for details). The wrapper will automatically call `done`
  when once it's done iterating over output lines.

- `"json"`: decodes generator output into JSON, sets `params.output` to the
  resulting JSON object, and calls `on_output(params)`. The wrapper will
  automatically call `done` once `on_output` returns.

- `"json_raw"`: same as `json`, but will not throw on errors, either from
  `stderr` or from `json_decode`. Instead, it'll pass errors to `on_output` via
  `params.err`.

### to_stderr

Captures a command's `stderr` output and assigns it to `params.output`. Useful
for linters that output to `stderr`.

### to_stdin

Sends the current buffer's content to the spawned command via `stdin`.

### ignore_errors

Suppresses errors, regardless of `stderr` output or the command's exit code.

Note that most formats won't call `on_output` if there is an error. To handle
errors manually, use `format = "raw"`.

### check_exit_code

A callback that receives one argument, `code`, which containing the exit code
from the spawned command as a number. The callback should return a boolean value
indicating whether the code indicates success.

If not specified, null-ls will assume that a non-zero exit code indicates
failure.

### timeout

The amount of time, in milliseconds, until null-ls aborts the command and
returns an empty response. If not set, will default to the user's
`default_timeout` setting.

### to_temp_file

Writes the current buffer's content to a temporary file and replaces the special
argument `$FILENAME` with the path to the temporary file. Useful for formatters
and linters that don't accept input via `stdin`.

## formatter_factory

`formatter_factory` is a wrapper around `generator_factory` meant to streamline
the process of capturing a formatter's output and replacing a buffer's entire
content with that output. It supports the same options as `generator_factory`
but will always override the following two options:

- `ignore_errors`: will always be `true`.

- `on_output`: will always return an edit object to replace the current buffer's
  content with formatter output. As a result, other options that depend on
  `on_output`, such as `format`, will not have an effect.

### make_builtin

`make_builtin` creates built-in sources, as described in
[BUILTINS](BUILTINS.md). It optimizes the source to reduce start-up time and
allow the built-in library to continue expanding without affecting users.

`make_builtin` is specifically intended for built-ins included in this plugin.
Generally, integrations should opt to create sources with one of the `factory`
methods described above, since they are opt-in by nature.

The method accepts a single argument, `opts`, which contains the following
options. All options are **required** unless specified otherwise.

```lua
local null_ls = require("null-ls")

null_ls.helpers.make_builtin({
    method, -- internal null-ls method (string)
    filetypes, -- table
    generator_opts, -- table
    factory, -- function (optional)
    generator, -- function (optional, but required if factory is not set)
})
```

### method

Defines the source's null-ls method, as described in [MAIN](MAIN.md).

### filetypes

A list of filetypes for the source, as described in [MAIN](MAIN.md). A
built-in can opt to leave this as `nil`, meaning that the user will have to
define filetypes in `with()`.

### generator_opts

A table of arguments passed into `factory` when the user registers the source,
which should conform to the `opts` object described above in
`generator_factory`.

### factory

A function called when the user registers the source. Intended for use with the
helper `factory` functions described above, but any function that returns a
valid generator will work.

### generator

A simple generator function. Either `factory` or `generator` must be a valid
function, and setting `factory` will override `generator`.
