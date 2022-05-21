<!-- markdownlint-configure-file
{
  "line-length": false,
  "no-duplicate-header": false
}
-->

# Installing and configuring null-ls

You can install null-ls using any package manager. Here is a simple example
showing how to install it and its dependencies using
[packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use({
    "jose-elias-alvarez/null-ls.nvim",
    config = function()
        require("null-ls").setup()
    end,
    requires = { "nvim-lua/plenary.nvim" },
})
```

As shown above, the plugin depends on
[plenary.nvim](https://github.com/nvim-lua/plenary.nvim), so make sure you've
installed that plugin, too.

Below is a simple example demonstrating how you might configure null-ls. See
[BUILTINS](BUILTINS.md) for a list of built-in sources like the ones in the
example below and [BUILTIN_CONFIG](BUILTIN_CONFIG.md) for information on how to
configure these sources.

```lua
require("null-ls").setup({
    sources = {
        require("null-ls").builtins.formatting.stylua,
        require("null-ls").builtins.diagnostics.eslint,
        require("null-ls").builtins.completion.spell,
    },
})
```

## Options

The following code block shows the available options and their defaults.

```lua
local defaults = {
    cmd = { "nvim" },
    debounce = 250,
    debug = false,
    default_timeout = 5000,
    diagnostics_format = "#{m}",
    fallback_severity = vim.diagnostic.severity.ERROR,
    log = {
        enable = true,
        level = "warn",
        use_console = "async",
    },
    on_attach = nil,
    on_init = nil,
    on_exit = nil,
    root_dir = u.root_pattern(".null-ls-root", "Makefile", ".git"),
    sources = nil,
    update_in_insert = false,
}
```

null-ls allows configuring a subset of the options used by nvim-lspconfig's
`setup` method (shared with `vim.lsp.start_client`), as described
[here](https://github.com/neovim/nvim-lspconfig/wiki/Understanding-setup-%7B%7D).
If an option you want to use is missing, open an issue or PR.

Note that setting `autostart = true` is unnecessary (and unsupported), as
null-ls will always attempt to attach to buffers automatically if you've
configured and registered sources.

### cmd (table)

Defines the command used to start the null-ls server. If you do not have an
`nvim` binary available on your `$PATH`, you should change this to an absolute
path to the binary.

### debounce (number)

The `debounce` setting controls the amount of time between the last change to a
buffer and the next `textDocument/didChange` notification. These notifications
cause null-ls to generate diagnostics, so this setting indirectly controls the
rate of diagnostic generation (affected by `update_in_insert`, described below).

Lowering `debounce` will result in quicker diagnostic refreshes at the cost of
running diagnostic sources more frequently, which can affect performance. The
default value should be enough to provide near-instantaneous feedback from most
sources without unnecessary resource usage.

### debug (boolean)

Displays all possible log messages and writes them to the null-ls log, which you
can view with the command `:NullLsLog`. This option can slow down Neovim, so
it's strongly recommended to disable it for normal use.

`debug = true` is the same as setting `log.level` to `"trace"` and
`log.use_console` to `false`. For finer-grained control, see the `log` options
below.

### default_timeout (number)

Sets the amount of time (in milliseconds) after which built-in sources will time
out. Note that built-in sources can define their own timeout period and that
users can override the timeout period on a per-source basis, too (see
[BUILTIN_CONFIG.md](BUILTIN_CONFIG.md)).

Specifying a timeout with a value less than zero will prevent commands from
timing out.

### diagnostics_format (string)

Sets the default format used for diagnostics. The plugin will replace the
following special components with the relevant diagnostic information:

- `#{m}`: message
- `#{s}`: source name (defaults to `null-ls` if not specified)
- `#{c}`: code (if available)

For example, setting `diagnostics_format` to the following:

```lua
diagnostics_format = "[#{c}] #{m} (#{s})"
```

Formats diagnostics as follows:

```txt
[2148] Tips depend on target shell and yours is unknown. Add a shebang or a 'shell' directive. (shellcheck)
```

You can also set `diagnostics_format` for built-ins by using the `with` method,
described in [BUILTIN_CONFIG](BUILTIN_CONFIG.md).

### fallback_severity (number)

Defines the severity used when a diagnostic source does not explicitly define a
severity. See `:help diagnostic-severity` for available values.

### log (table)

Sets options for null-ls logging.

#### log.enable (boolean)

Enables or disables logging altogether. Setting this to `false` will suppress
important operational warnings and is not recommended.

#### log.level (one of "error", "warn", "info", "debug", "trace")

Sets the logging level.

#### log.use_console (one of "sync", "async", false)

Determines whether to show log output in Neovim's `:messages`. `sync` is slower
but guarantees that messages will appear in order. Setting this to `false` will
skip the console but still log to the file specified by `:NullLsLog`.

### on_attach (function, optional)

Defines an `on_attach` callback to run whenever null-ls attaches to a buffer. If
you have a common `on_attach` you're using for LSP servers, you can reuse that
here, use a custom callback for null-ls, or leave this undefined.

### on_init (function, optional)

Defines an `on_init` callback to run when null-ls initializes. From here, you
can make changes to the client (the first argument) or `initialize_result` (the
second argument, which as of now is not used).

### on_exit (function, optional)

Defines an `on_exit` callback to run when the null-ls client exits.

### root_dir (function)

Determines the root of the null-ls server. On startup, null-ls will call
`root_dir` with the full path to the first file that null-ls attaches to.

```lua
local root_dir = function(fname)
    return fname:match("my-project") and "my-project-root"
end
```

If `root_dir` returns `nil`, the root will resolve to the current working
directory.

### should_attach (function, optional)

A user-defined function that controls whether to enable null-ls for a given
buffer. Receives `bufnr` as its first argument.

To cut down potentially expensive calls, null-ls will call `should_attach` after
its own internal checks pass, so it's not guaranteed to run on each new buffer.

```lua
require("null-ls.nvim").setup({
    should_attach = function(bufnr)
        return not vim.api.nvim_buf_get_name(bufnr):match("^git://")
    end,
})
```

### sources (table, optional)

Defines a list (array-like table) of sources for null-ls to register. Users can
add built-in sources (see [BUILTINS.md](BUILTINS.md)) or custom sources (see
[MAIN.md](MAIN.md)).

If you've installed an integration that provides its own sources and aren't
interested in built-in sources, you don't have to define any sources here. The
integration will register them independently.

### update_in_insert (boolean)

Controls whether diagnostic sources run in insert mode. If set to `false`,
diagnostic sources will run upon exiting insert mode, which greatly improves
performance but can create a slight delay before diagnostics show up. Set this
to `true` if you don't experience performance issues with your sources.

Note that by default, Neovim will not display updated diagnostics in insert
mode. Together with the option above, you need to pass `update_in_insert = true`
to `vim.diagnostic.config` for diagnostics to work as expected. See `:help vim.diagnostic.config` for more info.

## Explicitly defining the project root

Create an empty file `.null-ls-root` in the directory you want to mark as the
project root for null-ls.
