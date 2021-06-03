# Configuring null-ls

One of the goals of null-ls is to work out-of-the-box with minimal
configuration.

You can install null-ls using any package manager. Here is a simple example
using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use({ "jose-elias-alvarez/null-ls.nvim", config = function()
    require("null-ls").setup({})
end })
```

null-ls also depends on
[plenary.nvim](https://github.com/nvim-lua/plenary.nvim). It's required by other
popular plugins, so you may already have it installed.

Once installed, the minimal config required to enable null-ls is as follows:

```lua
require("null-ls").setup {}
```

Users can pass options in to the `setup()` function, but null-ls doesn't require
any options to set up.

Note that null-ls will not do anything until you've registered at least one
source via `setup()`, `register()`, or an integration.

See [BUILTINS](BUILTINS.md) for information about built-in sources or
[HELPERS](HELPERS.md) to see how to create your own.

## Options

The following code block shows the available options and their defaults.

```lua
local defaults = {
    debounce = 250,
    keep_alive_interval = 60000, -- 60 seconds,
    save_after_format = true,
    default_timeout = 5000,
    sources = nil,
    on_attach = nil,
}
```

## debounce (number)

The `debounce` setting controls the amount of time between the last change to a
buffer and the next diagnostic refresh. **It does not affect code actions or
formatting,** both of which run on demand.

Lowering `debounce` will result in more frequent diagnostic refreshes at the
cost of running diagnostic sources more frequently. The default value should be
enough to provide nearly-instantaneous feedback from most sources without
unnecessary resource usage.

### keep_alive_interval (number)

null-ls will shut down its server when Neovim exits, but if the editor crashes
or the user exits without autocommands, the server process will remain alive.
Accordingly, the server will shut down if it hasn't received a signal from the
client within the period specified (in milliseconds) by `keep_alive_interval`.

If you are consistently seeing orphaned null-ls processes after shutting down
Neovim, please open an issue.

### save_after_format (boolean)

By default, null-ls will save modified buffers after applying edits from
formatting sources. This makes it simple to enable asynchronous formatting on
save with the following snippet:

```lua
-- add to your lspconfig on_attach function
on_attach = function(client)
    if client.resolved_capabilities.document_formatting then
        u.buf_augroup("LspFormatOnSave", "BufWritePost", "lua vim.lsp.buf.formatting()")
    end
end
```

Setting `save_after_format = false` will leave the buffer in a modified state
after formatting, which is consistent with default LSP behavior.

### default_timeout (number)

Sets the amount of time (in milliseconds) after which built-in sources will time
out. Note that built-in sources can define their own timeout period and that
users can override the timeout period on a per-source basis, too (see
[BUILTINS.md](BUILTINS.md)).

### sources (list)

Defines a list of sources for null-ls to register. Users can add built-in
sources (see [BUILTINS.md](BUILTINS.md)) or custom sources (see
[MAIN.md](MAIN.md)).

If you've installed an integration that provides its own sources and aren't
interested in built-in sources, you don't have to define any sources here. The
integration will register them independently.

### on_attach (function)

Allows the user to pass in a custom `on_attach` function, which you are
(probably) already using to define LSP-specific keybindings and settings.

## Disabling null-ls

You can conditionally block null-ls setup on Neovim startup by setting
`vim.g.null_ls_disable = true` before `setup()` runs.

For example, you can use the following snippet to disable null-ls when using
[firenvim](https://github.com/glacambre/firenvim), as long as the module
containing the snippet loads before `setup()`:

```lua
if vim.g.started_by_firenvim then
    vim.g.null_ls_disable = true
end
```

Note that if you've already called `setup()`, null-ls will continue to attach to
new buffers. To shut down null-ls and prevent it from starting again in the current
Neovim instance, run `:lua require'null-ls'.disable()`.
