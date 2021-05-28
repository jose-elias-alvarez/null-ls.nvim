# null-ls.nvim

Use Neovim as a language server to inject LSP diagnostics, code actions, and
more via Lua.

## Motivation

Neovim's LSP ecosystem is growing, and plugins like
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) and
[trouble.nvim](https://github.com/folke/trouble.nvim) make it a joy to work with
LSP features like code actions and diagnostics.

Unlike the VS Code and coc.nvim ecosystems, Neovim doesn't provide a way for
non-LSP sources to hook into its LSP client. null-ls is, first of all, an
attempt to bridge that gap and simplify the process of creating, sharing, and
setting up LSP sources.

null-ls is also an attempt to reduce the confusion, bloat, and boilerplate
required for general-purpose language servers like
[efm-langserver](https://github.com/mattn/efm-langserver) and
[diagnostic-languageserver](https://github.com/iamcco/diagnostic-languageserver).
null-ls makes it straightforward to transform command-line output into a format
that Neovim's LSP client can handle, using Lua and without any extra executables
or overhead.

## Status

null-ls is in **pre-alpha status**, and breaking changes and bugs are a
near-certainty. Any and all feedback, criticism, or contributions about the
plugin's features, code quality, and user experience are greatly appreciated.

## Setup

Install null-ls using your favorite package manager. The plugin depends on
[plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

To enable the plugin, you must call `null_ls.setup {}` somewhere in your LSP
configuration, which will set up the necessary autocommands.

Note that null-ls will not do anything until you've registered at least one
source via `setup`, `register`, or a plugin integration. Once you've registered
a source, it'll activate on buffers with a matching filetype.

```lua
local null_ls = require("null-ls")

null_ls.setup {
    -- pass in your LSP on_attach callback
    on_attach = my_on_attach_callback,
    -- define sources at setup
    sources = {my_sources},

    -- options (defaults shown, numbers in ms)
    save_after_formatting = true,
    debounce = 250,
    keep_alive_interval = 60000,
    default_timeout = 5000
}

-- register sources dynamically
null_ls.register {other_sources}
```

## Examples

### Code actions (synchronous)

The following example demonstrates a (naive) filetype-independent source that
provides a code action to comment the current line using `commentstring`.

```lua
local null_ls = require("null-ls")
local api = vim.api

local comment_line = {
    method = null_ls.methods.CODE_ACTION,
    filetypes = {"*"},
    generator = {
        fn = function(params)
            -- sources have access to a params object
            -- containing info about the current file and editor state
            local bufnr = params.bufnr
            local line = params.content[params.row]

            -- all nvim api functions are safe to call
            local commentstring =
                api.nvim_buf_get_option(bufnr, "commentstring")

            -- null-ls combines and stores returned actions in its state
            -- and will call action() on execute
            return {
                {
                    title = "Comment line",
                    action = function()
                        api.nvim_buf_set_lines(bufnr, params.row - 1,
                                               params.row, false, {
                            string.format(commentstring, line)
                        })
                    end
                }
            }
        end
    }
}

null_ls.register(comment_line)
```

### Diagnostics (synchronous)

The following example demonstrates a diagnostic source that will show instances
of the word `really` in the current text as LSP warnings.

```lua
local null_ls = require("null-ls")
local api = vim.api

local no_really = {
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = {"markdown", "txt"},
    generator = {
        fn = function(params)
            local diagnostics = {}
            for i, line in ipairs(params.content) do
                local col, end_col = string.find(line, "really")
                if col and end_col then
                    -- null-ls fills in undefined positions
                    -- and converts source diagnostics into the required format
                    table.insert(diagnostics, {
                        row = i,
                        col = col - 1,
                        end_col = end_col,
                        source = "no-really",
                        message = "Don't use 'really!'",
                        severity = 2
                    })
                end
            end
            return diagnostics
        end
    }
}

null_ls.register(no_really)
```

### Code actions (asynchronous)

Asynchronous sources have access to a `done()` callback that, when called, will
signal their completion. The client uses plenary.nvim's async library to run
asynchronous sources concurrently and wait for all results before sending them
to Neovim's LSP client.

The following example demonstrates an asynchronous source that provides a code
action to insert a comment at the top of the current file containing its size,
which it gets asynchronously via `luv`.

```lua
local uv = vim.loop
local file_size_comment = {
    method = null_ls.methods.CODE_ACTION,
    filetypes = {"*"},
    generator = {
        -- must be explictly defined
        async = true,
        fn = function(params, done)
            local bufnr = params.bufnr
            local commentstring =
                api.nvim_buf_get_option(bufnr, "commentstring")

            uv.fs_open(params.bufname, "r", 438, function(_, fd)
                if not fd then return done() end

                uv.fs_fstat(fd, function(_, stat)
                    return done({
                        {
                            title = "Insert file size",
                            action = function()
                                api.nvim_buf_set_lines(bufnr, 0, 0, false, {
                                    string.format(commentstring,
                                                  "size: " .. stat.size)
                                })
                            end
                        }
                    })
                end)
            end)
        end
    }
}

null_ls.register(file_size_comment)
```

### Real-world usage

This [ESLint
integration](https://github.com/jose-elias-alvarez/nvim-lsp-ts-utils/blob/develop/lua/nvim-lsp-ts-utils/null-ls.lua)
from one of my plugins demonstrates a more elaborate example of parsing CLI JSON
output to generate sources for code actions, diagnostics, and formatting.

## Features

### Helpers

null-ls provides a helper, `null_ls.generator()`, to streamline the process of
spawning and transforming the output of command-line processes into an
LSP-friendly format. See the built-in files linked below for examples.

### Built-ins

null-ls includes built-in sources, meant to provide out-of-the-box
functionality. See [the wiki
page](https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Built-in-sources)
for details. Contributions to add more built-ins are welcome.

### Code actions

null-ls sources can provide code actions, which Neovim's LSP client will handle
and show alongside standard LSP code actions, either via the built-in code
action handler or a custom handler, like
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) or
[nvim-lspfuzzy](https://github.com/ojroques/nvim-lspfuzzy). The null-ls client
will then execute injected code actions as Lua functions, avoiding the need
to format JSON output.

### Diagnostics

null-ls sources can provide diagnostics, which the null-ls client will send to
Neovim's LSP client and show seamlessly alongside other sources. The null-ls
client subscribes to LSP file events and refreshes sources on file change after
a configurable debounce period.

### Formatting

null-ls can provide asynchronous LSP formatting, either with a custom generator
or by using the `null_ls.formatting()` helper, which wraps around
`null_ls.generator()`. See [the built-in formatting
file](lua/null-ls/builtins/formatting.lua) for examples.

## FAQ

### How does it work?

For a high-level overview: null-ls spawns a headless instance of Neovim as a
minimal RPC server, whose main purpose is to respond to Neovim's LSP client with
its capabilities. The client instance keeps the server alive and shuts it down
on exit or after a period of inactivity.

Everything else happens by modifying the client's `request` and `notify`
handlers to redirect or override their default behavior, run defined sources,
and send their output back to Neovim's LSP client.

### Will it affect my performance?

More testing is necessary, but informal metrics show that the performance impact
of running a (nearly) inactive headless instance of Neovim is minimal compared
to Node-based general-purpose language servers.

### Why hijack LSP features for non-LSP functionality? Why not use (other solution)?

Neovim's LSP ecosystem is wonderful, and I want to take advantage of it wherever
I can. Other ecosystems are also much freer about what defines a "valid" code
action or diagnostic - in fact, the inspiration for this plugin came from a
desire to replicate a [VS Code
plugin](https://github.com/Microsoft/vscode-eslint) that creates code actions
from the output of a CLI program.

Arguably, general-purpose language servers are already "cheating" by creating
what looks like LSP output from non-LSP programs. null-ls skips a step and keeps
it within Neovim.

## Tests

The test suite includes unit and integration tests and depends on plenary.nvim.
Run `make test` in the root of the project to run the suite or
`FILE=filename_spec.lua make test-file` to test an individual file.

## TODO

- [ ] Write proper documentation
- [ ] Add more built-ins
- [ ] Investigate other potential LSP integrations
