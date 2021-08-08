# null-ls.nvim

Use Neovim as a language server to inject LSP diagnostics, code actions, and
more via Lua.

## Motivation

Neovim's LSP ecosystem is growing, and plugins like
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) and
[trouble.nvim](https://github.com/folke/trouble.nvim) make it a joy to work with
LSP features like code actions and diagnostics.

Unlike the VS Code and coc.nvim ecosystems, Neovim doesn't provide a way for
non-LSP sources to hook into its LSP client. null-ls is an attempt to bridge
that gap and simplify the process of creating, sharing, and setting up LSP
sources using pure Lua.

null-ls is also an attempt to reduce the boilerplate required to set up
general-purpose language servers and improve performance by removing the need
for external processes.

## Status

null-ls is in **beta status**. Please open an issue if something doesn't
work the way you expect (or doesn't work at all).

At the moment, null-is is compatible with Neovim 0.5 (stable) and 0.6 (head),
but you'll get the best experience from the latest version you can run.

Note that null-ls is built on macOS and Linux and may not work as expected (or
at all) on Windows. Contributions to expand Windows support are welcome, but
since I don't work on Windows, my ability to diagnose or fix Windows issues is
nonexistent.

## Features

null-ls sources are able to hook into the following LSP features:

- Code actions

- Diagnostics

- Formatting (including range formatting)

null-ls includes built-in sources for each of these features to provide
out-of-the-box functionality. See [BUILTINS](doc/BUILTINS.md) for instructions on
how to set up sources and a list of available sources.

null-ls also provides helpers to streamline the process of spawning and
transforming the output of command-line processes into an LSP-friendly format.
If you want to create your own source, either for personal use or for a plugin,
see [HELPERS](doc/HELPERS.md) for details.

## Setup

Install null-ls using your favorite package manager. The plugin depends on
[plenary.nvim](https://github.com/nvim-lua/plenary.nvim) and
[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), both of which you
are (probably) already using.

Please see [CONFIG](doc/CONFIG.md) for information about setting up and
configuring null-ls.

At a minimum, you must register at least one source and set up the plugin's
integration with nvim-lspconfig, as in this example:

```lua
-- example configuration! (see CONFIG above to make your own)
require("null-ls").config({
    sources = { require("null-ls").builtins.formatting.stylua }
})
require("lspconfig")["null-ls"].setup({
    on_attach = my_custom_on_attach
})

```

## Documentation

The definitive source for information about null-ls is its
[documentation](doc/MAIN.md), which contains information about how null-ls
works, how to set it up, and how to create sources.

## Contributing

Contributions to add new features and built-ins for any language are always
welcome. See [CONTRIBUTING](doc/CONTRIBUTING.md) for guidelines.

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
        -- must be explicitly defined
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

null-ls formatters run when you call `vim.lsp.buf.formatting()`. If a source
supports it, you can run range formatting by visually selecting part of the
buffer and calling `vim.lsp.buf.range_formatting()`.

Note that `vim.lsp.buf.formatting_sync()` will not work properly when running
more than one formatter on a single filetype.

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
-- or to a common on_attach callback to enable for all supported filetypes
on_attach = function(client)
    if client.resolved_capabilities.document_formatting then
        vim.cmd("autocmd BufWritePost <buffer> lua vim.lsp.buf.formatting()")
    end
end
```

### Does it work with (other plugin)?

In most cases, yes. null-ls tries to act like an actual LSP server as much as
possible, so it should work seamlessly with most LSP-related plugins. If you run
into problems, please try to determine which plugin is causing them and open an
issue.

### How does it work?

Thanks to hard work by @folke, the plugin wraps the mechanism Neovim uses to
spawn language servers to start a client entirely in-memory. The client attaches
to buffers that match defined sources and receives and responds to requests,
document changes, and other events from Neovim.

### Will it affect my performance?

More testing is necessary, but since null-ls uses pure Lua and runs entirely in
memory without any external processes, in most cases it should run faster than
similar solutions. If you notice that performance is worse with null-ls than
with an alternative, please open an issue!

### How to enable and use debug mode

1. Set `debug` flag to `true` in the config like so:

   ```lua
   require("null-ls").config({
       debug = true
   })
   ```

2. When the error occurs, use `:messages` to see the debug output.

## Tests

The test suite includes unit and integration tests and depends on plenary.nvim.
Run `make test` in the root of the project to run the suite or
`FILE=filename_spec.lua make test-file` to test an individual file.

## Alternatives

- [efm-langserver](https://github.com/mattn/efm-langserver) and
  [diagnostic-languageserver](https://github.com/iamcco/diagnostic-languageserver):
  general-purpose language servers that can provide formatting and diagnostics
  (but not code actions) from CLI output. Both require installing external
  executables, and neither provides built-ins (and configuring them is, to put
  it nicely, unfriendly).

- [nvim-lint](https://github.com/mfussenegger/nvim-lint): a Lua plugin that
  focuses on providing diagnostics from CLI output. Provides built-in linters.
  Runs independently, which provides flexibility but requires users to define
  their own autocommands. Does not currently support writing to temp files for
  diagnostics.

- [formatter.nvim](https://github.com/mhartington/formatter.nvim): a Lua plugin
  that (surprise) focuses on formatting. Does not currently provide built-in
  formatters, meaning users have to define their own. Makes no attempt to
  integrate with LSP behavior (which may be an upside or a downside).
