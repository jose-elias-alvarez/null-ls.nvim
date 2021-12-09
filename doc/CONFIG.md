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
use({ "jose-elias-alvarez/null-ls.nvim",
    config = function()
        require("null-ls").config({})
        require("lspconfig")["null-ls"].setup({})
    end,
    requires = {"nvim-lua/plenary.nvim", "neovim/nvim-lspconfig"}
    })
```

As shown above, the plugin depends on
[plenary.nvim](https://github.com/nvim-lua/plenary.nvim) and
[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), so make sure you've
installed those, too.

Below is a simple example demonstrating how you might configure null-ls.
See [BUILTINS](BUILTINS.md) for information about built-in sources like the one
in the example below.

```lua
require("null-ls").config({
    -- you must define at least one source for the plugin to work
    sources = { require("null-ls").builtins.formatting.stylua }
})
require("lspconfig")["null-ls"].setup({
    -- see the nvim-lspconfig documentation for available configuration options
    on_attach = my_custom_on_attach
})
```

## Options

The following code block shows the available options and their defaults.

```lua
local defaults = {
    sources = nil,
    diagnostics_format = "#{m}",
    debounce = 250,
    default_timeout = 5000,
    update_on_insert = false,
    debug = false,
    log = {
        enable = true,
        level = "warn",
        use_console = "async",
    },
}
```

### sources (list)

Defines a list of sources for null-ls to register. Users can add built-in
sources (see [BUILTINS.md](BUILTINS.md)) or custom sources (see
[MAIN.md](MAIN.md)).

If you've installed an integration that provides its own sources and aren't
interested in built-in sources, you don't have to define any sources here. The
integration will register them independently.

### diagnostics_format (one of string, function)

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

Alternatively, a function taking a diagnostic and returning a string can be
provided:

```lua
diagnostics_format = function(diagnostic)
	if diagnostic.code then
		return string.format("[%s: %s] %s", diagnostic.source, diagnostic.code, diagnostic.message)
	end

	return string.format("[%s] %s", diagnostic.source, diagnostic.message)
end,
```

The structure of the diagnostic passed in matches the definition in
[MAIN](MAIN.md).

You can also set `diagnostics_format` for built-ins by using the `with` method,
described in [BUILTINS](BUILTINS.md).

### debounce (number)

The `debounce` setting controls the amount of time between the last change to a
buffer and the next diagnostic refresh. **It does not affect code actions or
formatting,** both of which run on demand.

Lowering `debounce` will result in more frequent diagnostic refreshes at the
cost of running diagnostic sources more frequently. The default value should be
enough to provide near-instantaneous feedback from most sources without
unnecessary resource usage.

### default_timeout (number)

Sets the amount of time (in milliseconds) after which built-in sources will time
out. Note that built-in sources can define their own timeout period and that
users can override the timeout period on a per-source basis, too (see
[BUILTINS.md](BUILTINS.md)).

### update_on_insert (boolean)

Controls whether diagnostic sources run in insert mode. If set to `false`,
diagnostic sources will run only upon exiting insert mode, which greatly
improves performance but can create a slight delay before diagnostics show up.
Set this to `true` if you don't experience performance issues with your sources.

### debug (boolean)

Displays all possible log messages and writes them to the null-ls log, which you
can view with the command `:NullLsLog`. This option can slow down Neovim, so
it's strongly recommended to disable it for normal use.

`debug = true` is the same as setting `log.level` to `"trace"` and
`log.use_console` to `false`. For finer-grained control, see the `log` options
below.

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

## Disabling null-ls

You can conditionally block null-ls from setting itself up on Neovim startup by
setting `vim.g.null_ls_disable = true` before `config` runs.

For example, you can use the following snippet to disable null-ls when using
[firenvim](https://github.com/glacambre/firenvim), as long as the module
containing the snippet loads before `config`:

```lua
if vim.g.started_by_firenvim then
    vim.g.null_ls_disable = true
end
```

If null-ls is already running but you want to stop it, you can use the methods
provided by nvim-lspconfig (`:LspStart`, `:LspStop`, and `:LspRestart`) to
control its behavior.

You can also deregister sources using the source API, as described in
[SOURCES](SOURCES.md).

## Explicitly defining the project root

Create an empty file `.null-ls-root` in the directory you want to mark as the project root for null-ls.
