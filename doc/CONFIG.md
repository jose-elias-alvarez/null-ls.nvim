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
    debounce = 250,
    save_after_format = true,
    default_timeout = 5000,
    sources = nil,
}
```

## debounce (number)

The `debounce` setting controls the amount of time between the last change to a
buffer and the next diagnostic refresh. **It does not affect code actions or
formatting,** both of which run on demand.

Lowering `debounce` will result in more frequent diagnostic refreshes at the
cost of running diagnostic sources more frequently. The default value should be
enough to provide near-instantaneous feedback from most sources without
unnecessary resource usage.

### save_after_format (boolean)

By default, null-ls will save modified buffers after applying edits from
formatting sources. This makes it simple to enable asynchronous formatting on
save with the following snippet:

```lua
-- add to your lspconfig on_attach function
on_attach = function(client)
    if client.resolved_capabilities.document_formatting then
        vim.cmd("autocmd BufWritePost <buffer> lua vim.lsp.buf.formatting()")
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

## Disabling null-ls

You can conditionally block null-ls setup on Neovim startup by setting
`vim.g.null_ls_disable = true` before `config()` runs.

For example, you can use the following snippet to disable null-ls when using
[firenvim](https://github.com/glacambre/firenvim), as long as the module
containing the snippet loads before `config()`:

```lua
if vim.g.started_by_firenvim then
    vim.g.null_ls_disable = true
end
```

If null-ls is already running but you want to stop it, you can use the methods
provided by nvim-lspconfig (`:LspStart`, `:LspStop`, and `:LspRestart`) to
control its behavior.
