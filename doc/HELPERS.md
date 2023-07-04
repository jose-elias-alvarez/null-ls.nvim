# Helpers

null-ls provides helpers to streamline the process of transforming command line
output into LSP diagnostics, code actions, or formatting.

The plugin exports available helpers under `null_ls.helpers`:

```lua
local helpers = require("null-ls.helpers")
```

Please see the [built-in files](../lua/null-ls/builtins/) for examples of how to
use helpers to create generators.

## Params

Descriptions below may refer to a `params` table, which is a table containing
information about the current editor state. For details on the structure of this
table and its available keys / methods, see [MAIN](./MAIN.md).

## generator_factory

`generator_factory` is a general-purpose helper that returns a generator which
spawns a command with the given options, optionally transforms its output, then
calls an `on_output` callback with the command's output. It accepts one
argument, `opts`, which is a table with the following structure.

All options are **required** unless specified otherwise.

```lua
local helpers = require("null-ls.helpers")

helpers.generator_factory({
    args, -- function or table (optional)
    check_exit_code, -- function or table of numbers (optional)
    command, -- string or function
    cwd, -- function (optional)
    dynamic_command, -- function (optional)
    env, -- function or table (optional)
    format, -- "raw", "line", "json", or "json_raw" (optional)
    from_stderr, -- boolean (optional)
    from_temp_file, -- boolean (optional)
    ignore_stderr, -- boolean (optional)
    multiple_files, -- boolean (optional)
    on_output, -- function
    runtime_condition, -- function (optional)
    timeout, -- number (optional)
    to_stdin, -- boolean (optional)
    to_temp_file, -- boolean (optional)
    use_cache, -- boolean (optional)
    prepend_extra_args, -- boolean (optional)
})
```

null-ls validates each option using `vim.validate` when the generator runs for
the first time.

### args

A table containing the arguments passed when spawning the command or a function
that takes one argument, a `params` table, and returns an `args` table. Defaults
to `{}`.

null-ls will transform the following special arguments before spawning:

- `$FILENAME`: replaced with the current buffer's full path

- `$DIRNAME`: replaced with the current buffer's parent directory

- `$TEXT`: replaced with the current buffer's content

- `$FILEEXT`: replaced with the current buffer's file extension (e.g.
  `my-file.lua` produces `"lua"`)

- `$ROOT`: replaced with the LSP workspace root path

### check_exit_code

Can either be a table of valid exit codes (numbers) or a callback that receives
two arguments:

`code`: contains the exit code from the spawned command as a number `stderr`:
error output from the job as a string

The callback should return a boolean value indicating whether the code indicates
_success_.

If not specified, null-ls will assume that a non-zero exit code indicates
failure.

### command

A string containing the command that the generator will spawn or a function that
takes one argument, a `params` table, and returns a command string.

If `command` is a function, it will run once when the generator first runs and
keep the same return value as long as the same Neovim instance is running,
making it suitable for resolving executables based on the current project.

### cwd

Optional callback to set the working directory for the spawned process. Takes a
single argument, a `params` table. If the callback returns `nil`, the working
directory defaults to the project's root.

### dynamic_command

Optional callback to set `command` dynamically. Takes one arguments, a `params`
table. The generator's original command (if set) is available as
`params.command`. The callback should return a string containing the command to
run or `nil`, meaning that no command should run.

`dynamic_command` runs every time its parent generator runs and can affect
performance, so it's best to cache its output when possible.

Note that setting `dynamic_command` will disable `command` validation.

### env

A key-value pair table containing the environment variables passed when spawning
the command or a function that takes one argument, a `params` table, and returns
an `env` table. Defaults to `nil`.

### format

Specifies the format used to transform output before passing it to `on_output`.
Supports the following options:

- `"raw"`: passes command output directly as `params.output` (string) and error
  output as `params.err` (string).

  This format will call `on_output(params, done)`, where `done()` is a callback
  that `on_output` must call with its results (see _Generators_ in
  [MAIN](MAIN.md) for details).

- `nil`: same as `raw`, but does not receive error output. Instead, any output
  to `stderr` will cause the generator to throw an error, unless `ignore_stderr`
  is also enabled (see below).

- `"line"`: splits generator output into lines and calls
  `on_output(line, params)` once for each line, where `line` is a string.

- `"json"`: decodes generator output into JSON, sets `params.output` to the
  resulting JSON object, and calls `on_output(params)`. The wrapper will
  automatically call `done` once `on_output` returns.

- `"json_raw"`: same as `json`, but will not throw on errors, either from
  `stderr` or from `json.decode`. Instead, it'll pass errors to `on_output` via
  `params.err`.

To sum up:

- If you want to handle each line of a source's output, use `format = "line"`.

- If you are handling JSON output, use `format = "json"` if you don't intend on
  handling errors and `format = "json_raw"` if you do.

- If you are processing a source's entire output, use `format = nil` if you
  don't intend on handling errors and `format = "raw"` if you do.

### from_stderr

Captures a command's `stderr` output and assigns it to `params.output`. Note
that setting `from_stderr = true` will discard any `stdin` output.

Not compatible with `ignore_stderr`.

### from_temp_file

Reads the contents of the temp file created by `to_temp_file` after running
`command` and assigns it to `params.output`. Useful for formatters that don't
output to `stdin` (see `formatter_factory`).

This option depends on `to_temp_file`.

### ignore_stderr

For non-`raw` output formats, any output to `stderr` causes a command to fail
(unless `from_stderr` is `true`, as described above).

This option tells the runner to ignore the command's `stderr` output. This is
like redirecting a command's output with `2>/dev/null`, but any error output is
still logged when `debug` mode is on.

### multiple_files

If set, signals that the generator will return results that apply to more than
one file. The null-ls diagnostics handler allows applying results to more than
one file if this option is `true` and each diagnostic specifies a `bufnr` or
`filename` specifying the file to which the diagnostic applies.

### on_output

A callback function that receives a single argument, a `params` table.

Generators created by `generator_factory` have access to an extra parameter,
`params.output`, which contains the output from the spawned command. The
structure of `params.output` depends on `format`, described below.

### runtime_condition

Optional callback called when generating a list of sources to run for a given
method. Takes a single argument, a `params` table. If the callback's return
value is falsy, the source does not run.

Be aware that the callback runs _every_ time a source can run and thus should
avoid doing anything overly expensive.

### timeout

The amount of time, in milliseconds, until null-ls aborts the command and
returns an empty response. If not set, will default to the user's
`default_timeout` setting.

### to_stdin

Sends the current buffer's content to the spawned command via `stdin`.

### to_temp_file

Writes the current buffer's content to a temporary file and replaces the special
argument `$FILENAME` with the path to the temporary file. Useful for formatters
and linters that don't accept input via `stdin`.

Setting `to_temp_file = true` will also assign the path to the temp file to
`params.temp_path`.

### use_cache

Caches command output on run. When available, the generator will use cached
output instead of spawning the command, which can increase performance for slow
commands.

The plugin resets cached output when Neovim's LSP client notifies it of a buffer
change, meaning that cache validity depends on a user's `debounce` setting.
Sources that rely on up-to-date buffer content should avoid using this option.

Note that this option effectively does nothing for diagnostics, since the
handler will always invalidate the buffer's cache before running generators.

### prepend_extra_args

Prepends the extra_args from the user before the ones provided in the
generator_ops if true.

This can be needed for some commands that need specific order to work.

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

`make_builtin` creates built-in sources. It optimizes the source to reduce
start-up time and allow the built-in library to continue expanding without
affecting users.

`make_builtin` is specifically intended for built-ins included in this plugin.
Generally, integrations should opt to create sources with one of the `factory`
methods described above, since they are opt-in by nature.

The method accepts a single argument, `opts`, which contains the following
options. All options are **required** unless specified otherwise.

```lua
local helpers = require("null-ls.helpers")

helpers.make_builtin({
    factory, -- function (optional)
    filetypes, -- table
    generator, -- function (optional, but required if factory is not set)
    generator_opts, -- table
    method, -- internal null-ls method (string)
    meta, -- table
})
```

### factory

A function called when the user registers the source. Intended for use with the
helper `factory` functions described above, but any function that returns a
valid generator will work.

### filetypes

A list of filetypes for the source, as described in [MAIN](MAIN.md).

### generator

A simple generator function. Either `factory` or `generator` must be a valid
function, and setting `factory` will override `generator`.

### generator_opts

A table of arguments passed into `factory` when the user registers the source,
which should conform to the `opts` object described above in
`generator_factory`.

### method

Defines the source's null-ls method, as described in [MAIN](MAIN.md).

### meta

Adds metadata to enrich the source's documentation. null-ls will use the
following fields:

- `meta.url`: the path to the source's official website / repository
- `meta.description`: a description of the source and its capabilities
- `meta.notes`: an array of notes converted into a Markdown list

## range_formatting_args_factory

Converts the visually-selected range into character offsets / rows and adds the
converted range to the spawn arguments. Used for sources that provide both
formatting and range formatting.

```lua
null_ls.helpers.range_formatting_args_factory(base_args, start_arg, end_rag, opts)
```

- `base_args` (string[]): the base arguments required to get formatted output.
  Formatting requests will use `base_args` as-is and range formatting requests
  will append range arguments.

- `start_arg` (string): the name of the argument that indicates the start of the
  range.

- `end_arg` (string?): the name of the argument that indicates the end of the
  range. If not specified, the helper will insert the start and end of the range
  after `start_arg`.

- `opts` (table?): a table containing the following options:
  - `opts.use_rows` (boolean?): specifies whether to use rows over character
    offsets.
  - `opts.use_length` (boolean?): used to specify the length of the range in
    `end_arg` instead of end the position.
  - `opts.row_offset` (number?): offset applied to row numbers.
  - `opts.col_offset` (number?): offset applied to column numbers.
  - `opts.delimiter` (string?): used to join range start and end into a single
    argument.

## diagnostics

Helpers used to convert CLI output into diagnostics. See the source for details
and the built-in diagnostics sources for examples.

## cache

Helpers used to cache output from callbacks and help improve performance.

### by_bufnr(callback)

Creates a function that caches the result of `callback`, indexed by `bufnr`. On
the first run of the created function, null-ls will call `callback` with a
`params` table. On the next run, it will directly return the cached value
without calling `callback` again.

This is useful when the return value of `callback` is not expected to change
over the lifetime of the buffer, which works well for `cwd` and
`runtime_condition` callbacks. Users can use it as a simple shortcut to improve
performance, and built-in authors can use it to add logic that would otherwise
be too performance-intensive to include out-of-the-box.

Note that if `callback` returns `nil`, the helper will override the return value
and instead cache `false` (so that it can determine that it already ran
`callback` once and should not run it again).
