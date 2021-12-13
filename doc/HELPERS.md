# Helpers

null-ls provides helpers to streamline the process of transforming command line
output into LSP diagnostics, code actions, or formatting.

The plugin exports available helpers under `null_ls.helpers`:

```lua
local helpers = require("null-ls.helpers")
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
local helpers = require("null-ls.helpers")

helpers.generator_factory({
    command, -- string or function
    args, -- table (optional)
    on_output, -- function
    format, -- "raw", "line", "json", or "json_raw" (optional)
    ignore_stderr, -- boolean (optional)
    from_stderr, -- boolean (optional)
    to_stdin, -- boolean (optional)
    check_exit_code, -- function or table of numbers (optional)
    timeout, -- number (optional)
    to_temp_file, -- boolean (optional)
    use_cache, -- boolean (optional)
    runtime_condition, -- function (optional)
    cwd, -- function (optional)
    dynamic_command, -- function (optional)
    multiple_files, -- boolean (optional)
})
```

null-ls validates each option using `vim.validate` when the generator runs for
the first time.

### command

A string containing the command that the generator will spawn or a function that
takes one argument, `params` (an object containing information about the current
editor status) and returns a command string.

If `command` is a function, it will run once when the generator first runs and
keep the same return value as long as the same Neovim instance is running,
making it suitable for resolving executables based on the current project.

### args

A table containing the arguments passed when spawning the command. Defaults to `{}`.

null-ls will transform the following special arguments before spawning:

- `$FILENAME`: replaced with the current buffer's full path

- `$TEXT`: replaced with the current buffer's content

- `$FILEEXT`: replaced with the current buffer's file extension (e.g.
  `my-file.lua` produces `"lua"`)

- `$ROOT`: replaced with the LSP workspace root path

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

- `nil`: same as `raw`, but does not receive error output. Instead, any output
  to `stderr` will cause the generator to throw an error, unless `ignore_stderr`
  is also enabled (see below).

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
  `stderr` or from `json.decode`. Instead, it'll pass errors to `on_output` via
  `params.err`.

### ignore_stderr

For non-`raw` output formats, any output to `stderr` causes a command to fail
(unless `from_stderr` is `true`, as described below).

This option tells the runner to ignore the command's `stderr` output. This is
like redirecting a command's output with `2>/dev/null`, but any error output is
still logged when `debug` mode is on.

### from_stderr

Captures a command's `stderr` output and assigns it to `params.output`. Note
that setting `from_stderr = true` will discard any `stdin` output.

Not compatible with `ignore_stderr`.

### to_stdin

Sends the current buffer's content to the spawned command via `stdin`.

### check_exit_code

Can either be a table of valid exit codes (numbers) or a callback that receives
one argument, `code`, which containing the exit code from the spawned command as
a number. The callback should return a boolean value indicating whether the code
indicates success.

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

Setting `to_temp_file = true` will also assign the path to the temp file to
`params.temp_path`.

### from_temp_file

Reads the contents of the temp file created by `to_temp_file` after running
`command` and assigns it to `params.content`. Useful for formatters that don't
output to `stdin` (see `formatter_factory`).

This option depends on `to_temp_file`.

### use_cache

Caches command output on run. When available, the generator will use cached
output instead of spawning the command, which can increase performance for slow
commands.

The plugin resets cached output when Neovim's LSP client notifies it of a buffer
change, meaning that cache validity depends on a user's `debounce` setting.
Sources that rely on up-to-date buffer content should avoid using this option.

Note that this option effectively does nothing for diagnostics, since the
handler will always invalidate the buffer's cache before running generators.

### runtime_condition

Optional callback called when generating a list of sources to run for a given
method. Takes a single argument, `params`, which is a table containing
information about the current editor state (described in [MAIN](./MAIN.md)). If
the callback's return value is falsy, the source does not run.

Be aware that the callback runs _every_ time a source can run and thus should
avoid doing anything overly expensive.

### cwd

Optional callback to set the working directory for the spawned process. Takes a
single argument, `params`, which is a table containing information about the
current editor state (described in [MAIN](./MAIN.md)). If the callback returns
`nil`, the working directory defaults to the project's root.

### dynamic_command

Optional callback to set `command` dynamically. Takes one arguments, a `params`
object containing information about the current buffer's state. The generator's
original command (if set) is available as `params.command`. The callback should
return a string containing the command to run or `nil`, meaning that no command
should run.

`dynamic_command` runs every time its parent generator runs and can affect
performance, so it's best to cache its output when possible.

Note that setting `dynamic_command` will disable `command` validation.

### multiple_files

If set, signals that the generator will return results that apply to more than
one file. The null-ls diagnostics handler allows applying results to more than
one file if this option is `true` and each diagnostic specifies a `bufnr` or
`filename` specifying the file to which the diagnostic applies.

## formatter_factory

`formatter_factory` is a wrapper around `generator_factory` meant to streamline
the process of capturing a formatter's output and replacing a buffer's entire
content with that output. It supports the same options as `generator_factory`
with the following changes:

- `ignore_stderr`: set to `true` by default.

- `on_output`: will always return an edit that will replace the current buffer's
  content with formatter output. As a result, other options that depend on
  `on_output`, such as `format`, will not have an effect.

## make_builtin

`make_builtin` creates built-in sources, as described in
[BUILTINS](BUILTINS.md). It optimizes the source to reduce start-up time and
allow the built-in library to continue expanding without affecting users.

`make_builtin` is specifically intended for built-ins included in this plugin.
Generally, integrations should opt to create sources with one of the `factory`
methods described above, since they are opt-in by nature.

The method accepts a single argument, `opts`, which contains the following
options. All options are **required** unless specified otherwise.

```lua
local helpers = require("null-ls.helpers")

helpers.make_builtin({
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

## range_formatting_args_factory

Converts the visually-selected range into character offsets and adds the
converted range to the spawn arguments. Used for sources that provide both
formatting and range formatting.

```lua
null_ls.helpers.range_formatting_args_factory(base_args, start_arg, end_rag)
```

- `base_args`: the base arguments required to get formatted output. Formatting
  requests will use `base_args` as-is, and range formatting requests will append
  the range arguments.

- `start_arg` (optional): the name of the argument that indicates the start of
  the range. Defaults to `"--range-start"`.

- `end_arg` (optional): the name of the argument that indicates the end of the
  range. Defaults to `"--range-end"`.

## conditional

Used to conditionally register sources. See [HELPERS](HELPERS.md) for
more information.

## diagnostics

Helpers used to convert CLI output into diagnostics. See the source for details
and the built-in diagnostics sources for examples.
