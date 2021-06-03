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

null-ls is in **alpha status**. I'll do my best to avoid breaking changes that
affect users or integrations, but bugs are inevitable, and the plugin's behavior
might not yet match user expectations. Please open an issue if something doesn't
work the way you expect (or doesn't work at all).

Any and all feedback, criticism, or contributions about the plugin's features,
code quality, and user experience are greatly appreciated.

## Features

null-ls sources are able to hook into the following LSP features:

- Code actions

- Diagnostics

- Formatting

null-ls includes built-in sources for each of these features to provide
out-of-the-box functionality. See [BUILTINS](doc/BUILTINS.md) for instructions on
how to set up sources and a list of available sources.

Contributions to add more built-ins for any language are always welcome.

null-ls also provides helpers to streamline the process of spawning and
transforming the output of command-line processes into an LSP-friendly format.
If you want to create your own source, either for personal use or for a plugin,
see [HELPERS](doc/HELPERS.md) for details.

## Setup

Install null-ls using your favorite package manager. The plugin depends on
[plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

To enable the plugin, you must call `null_ls.setup {}` somewhere in your LSP
configuration, which will set up the necessary autocommands. You must then
register a source, either manually or via an integration.

Please see [CONFIG](doc/CONFIG.md) for information about setting up and
configuring null-ls.

## Documentation

The definitive source for information about null-ls is its
[documentation](doc/MAIN.md), which is still a work in progress but contains
information about how null-ls works, how to set it up, and how to create
sources.

## Examples

### Code actions

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

### Diagnostics

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
from one of my plugins demonstrates a more elaborate example of parsing JSON
output from a command to generate sources for code actions, diagnostics, and
formatting.

## FAQ

### How do I format files?

null-ls formatters run when you call `vim.lsp.buf.formatting()` or
`vim.lsp.buf.formatting_sync()`.

If you have other language servers running that can format the current buffer,
Neovim will prompt you to choose a formatter. You can prevent actual LSP clients
from providing formatting by adding the following snippet to your LSP
`on_attach` callback:

```lua
-- add to the on_attach callback for the server you want to disable
on_attach = function(client)
    client.resolved_capabilities.document_formatting = false
end
```

### How do I format files on save?

See the following snippet:

```lua
-- add to a specific server's on_attach,
-- or to a shared on_attach to enable for all supported filetypes
on_attach = function(client)
    if client.resolved_capabilities.document_formatting then
        u.buf_augroup("LspFormatOnSave", "BufWritePost", "lua vim.lsp.buf.formatting()")
    end
end
```

### Does it work with (other plugin)?

In most cases, yes. null-ls tries to act like an actual LSP server as much as
possible, so it should work seamlessly with most LSP-related plugins, but it
makes some compromises when necessary. If you run into problems, please open an
issue.

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
to the overhead required by a general-purpose language server.

Since null-ls uses pure Lua, minimizes server communication, and removes the
need to communicate via JSON, in most cases it should (theoretically) run faster
than similar solutions.

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

- [ ] Continue improving documentation
- [ ] Add more built-ins
- [ ] Investigate other potential LSP integrations
