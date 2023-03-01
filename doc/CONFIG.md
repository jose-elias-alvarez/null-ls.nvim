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
local null_ls = require("null-ls")

null_ls.setup({
    sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.diagnostics.eslint,
        null_ls.builtins.completion.spell,
    },
})
```

## Options

The following code block shows the available options and their defaults.

```lua
local defaults = {
    border = nil,
    cmd = { "nvim" },
    debounce = 250,
    debug = false,
    default_timeout = 5000,
    diagnostic_config = {},
    diagnostics_format = "#{m}",
    fallback_severity = vim.diagnostic.severity.ERROR,
    log_level = "warn",
    notify_format = "[null-ls] %s",
    on_attach = nil,
    on_init = nil,
    on_exit = nil,
    root_dir = require("null-ls.utils").root_pattern(".null-ls-root", "Makefile", ".git"),
    should_attach = nil,
    sources = nil,
    temp_dir = nil,
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

### border (table|string, optional)

Defines the border to use for the `:NullLsInfo` UI window. Uses
`NullLsInfoBorder` highlight group (see [Highlight Groups](#highlight-groups)).
Accepts same border values as `nvim_open_win()`. See `:help nvim_open_win()` for
more info.

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

`debug = true` is the same as setting `log_level` to `"trace"`.

### default_timeout (number)

Sets the amount of time (in milliseconds) after which built-in sources will time
out. Note that built-in sources can define their own timeout period and that
users can override the timeout period on a per-source basis, too (see
[BUILTIN_CONFIG.md](BUILTIN_CONFIG.md)).

Specifying a timeout with a value less than zero will prevent commands from
timing out.

### diagnostic_config (table, optional)

Specifies diagnostic display options for null-ls sources, as described in
`:help vim.diagnostic.config()`. (null-ls uses separate namespaces for each
source, so server-wide configuration will not work as expected.)

You can also configure `diagnostic_config` per built-in by using the `with`
method, described in [BUILTIN_CONFIG](BUILTIN_CONFIG.md).

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

You can also configure `diagnostics_format` per built-in by using the `with`
method, described in [BUILTIN_CONFIG](BUILTIN_CONFIG.md).

### fallback_severity (number)

Defines the severity used when a diagnostic source does not explicitly define a
severity. See `:help diagnostic-severity` for available values.

### log_level (string, one of "off", "error", "warn", "info", "debug", "trace")

Enables or disables logging to file.

Plugin logs messages on several logging levels to following destinations:

- file, can be inspected by `:NullLsLog`.
- neovim's notification area.

### notify_format (string, optional)

Sets the default format for `vim.notify()` messages. Can be used to customize
3rd party notification plugins like
[nvim-notify](https://github.com/rcarriga/nvim-notify).

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

### temp_dir (string, optional)

Defines the directory used to create temporary files for sources that rely on
them (a workaround used for command-based sources that do not support `stdio`).

To maximize compatibility, null-ls defaults to creating temp files in the same
directory as the parent file. If this is causing issues, you can set it to
`/tmp` (or another appropriate directory) here. Otherwise, there is no need to
change this setting.

**Note**: some null-ls built-in sources expect temp files to exist within a
project for context and so will not work if this option changes.

You can also configure `temp_dir` per built-in by using the `with` method,
described in [BUILTIN_CONFIG](BUILTIN_CONFIG.md).

### update_in_insert (boolean)

Controls whether diagnostic sources run in insert mode. If set to `false`,
diagnostic sources will run upon exiting insert mode, which greatly improves
performance but can create a slight delay before diagnostics show up. Set this
to `true` if you don't experience performance issues with your sources.

Note that by default, Neovim will not display updated diagnostics in insert
mode. Together with the option above, you need to pass `update_in_insert = true`
to `vim.diagnostic.config` for diagnostics to work as expected. See
`:help vim.diagnostic.config` for more info.

## Highlight Groups

Below are the highlight groups that you can override for the `:NullLsInfo`
window.

- `NullLsInfoHeader` Window header
- `NullLsInfoTitle` Titles
- `NullLsInfoBorder` Window border
- `NullLsInfoSources` Sources names

## Explicitly defining the project root

Create an empty file `.null-ls-root` in the directory you want to mark as the
project root for null-ls.
