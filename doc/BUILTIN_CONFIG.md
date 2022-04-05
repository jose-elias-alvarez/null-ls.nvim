<!-- markdownlint-configure-file
{
  "line-length": false,
  "no-duplicate-header": false
}
-->

# Using and configuring built-in sources

null-ls includes a library of built-in sources meant to provide out-of-the-box
functionality. Built-in sources run with optimizations to reduce startup time
and enable user customization.

See [BUILTINS](BUILTINS.md) for a list of available built-in sources.

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

### Diagnostics on save

If the documentation lists a source's method as `diagnostics_on_save`, that
source **will not run on change**. The diagnostics you see will not reflect
changes to the buffer until you write those changes to the disk.

Typically, this is a workaround for linters that require project context to
produce accurate results, and overriding the method will not work.

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

Specifying a timeout with a value less than zero will prevent the command from
ever timing out.

### Running in place

Some builtins write the buffer to a temp file before being executed. This can be
turned off by setting `to_temp_file` to `false`:

```lua
local sources = {
    null_ls.builtins.formatting.phpstan.with({
        to_temp_file = false
    }),
}
```

If overriding this it is recommended to switch diagnostics to
[run on save](#diagnostics-on-save).

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
