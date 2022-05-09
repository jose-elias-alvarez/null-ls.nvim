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

null-ls is in **beta status**. Please see below for steps to follow if something
doesn't work the way you expect (or doesn't work at all).

At the moment, null-is is compatible with Neovim 0.7 (stable) and 0.8 (head),
but some features and performance improvements are exclusive to the latest
version.

## Features

null-ls sources are able to hook into the following LSP features:

- Code actions

- Diagnostics (file- and project-level)

- Formatting (including range formatting)

- Hover

- Completion

null-ls includes built-in sources for each of these features to provide
out-of-the-box functionality. See [BUILTINS](doc/BUILTINS.md) for a list of
available built-in sources and [BUILTIN_CONFIG](doc/BUILTIN_CONFIG.md) for
instructions on how to set up and configure these sources.

null-ls also provides helpers to streamline the process of spawning and
transforming the output of command-line processes into an LSP-friendly format.
If you want to create your own source, either for personal use or for a plugin,
see [HELPERS](doc/HELPERS.md) for details.

## Setup

Install null-ls using your favorite package manager. The plugin depends on
[plenary.nvim](https://github.com/nvim-lua/plenary.nvim), which you are
(probably) already using.

To get started, you must set up null-ls and register at least one source. See
[BUILTINS](doc/BUILTINS.md) for a list of available built-in sources and
[CONFIG](doc/CONFIG.md) for information about setting up and configuring
null-ls.

```lua
require("null-ls").setup({
    sources = {
        require("null-ls").builtins.formatting.stylua,
        require("null-ls").builtins.diagnostics.eslint,
        require("null-ls").builtins.completion.spell,
    },
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

### Parsing buffer content

The following example demonstrates a diagnostic source that will parse the
current buffer's content and show instances of the word `really` as LSP
warnings.

```lua
local null_ls = require("null-ls")
local api = vim.api

local no_really = {
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = { "markdown", "text" },
    generator = {
        fn = function(params)
            local diagnostics = {}
            -- sources have access to a params object
            -- containing info about the current file and editor state
            for i, line in ipairs(params.content) do
                local col, end_col = line:find("really")
                if col and end_col then
                    -- null-ls fills in undefined positions
                    -- and converts source diagnostics into the required format
                    table.insert(diagnostics, {
                        row = i,
                        col = col,
                        end_col = end_col,
                        source = "no-really",
                        message = "Don't use 'really!'",
                        severity = 2,
                    })
                end
            end
            return diagnostics
        end,
    },
}

null_ls.register(no_really)
```

### Parsing CLI program output

null-ls includes helpers to simplify the process of spawning and capturing the
output of CLI programs. This example shows how to pass the content of the
current buffer to `markdownlint` via `stdin` and convert its output (which it
sends to `stderr`) into LSP diagnostics:

```lua
local null_ls = require("null-ls")
local helpers = require("null-ls.helpers")

local markdownlint = {
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = { "markdown" },
    -- null_ls.generator creates an async source
    -- that spawns the command with the given arguments and options
    generator = null_ls.generator({
        command = "markdownlint",
        args = { "--stdin" },
        to_stdin = true,
        from_stderr = true,
        -- choose an output format (raw, json, or line)
        format = "line",
        check_exit_code = function(code, stderr)
            local success = code <= 1

            if not success then
              -- can be noisy for things that run often (e.g. diagnostics), but can
              -- be useful for things that run on demand (e.g. formatting)
              print(stderr)
            end

            return success
        end,
        -- use helpers to parse the output from string matchers,
        -- or parse it manually with a function
        on_output = helpers.diagnostics.from_patterns({
            {
                pattern = [[:(%d+):(%d+) [%w-/]+ (.*)]],
                groups = { "row", "col", "message" },
            },
            {
                pattern = [[:(%d+) [%w-/]+ (.*)]],
                groups = { "row", "message" },
            },
        }),
    }),
}

null_ls.register(markdownlint)
```

## FAQ

### Something isn't working! What do I do?

**NOTE**: If you run into issues when using null-ls, please follow the steps
below and **do not** open an issue on the Neovim repository. null-ls is not an
actual LSP server, so we need to determine whether issues are specific to this
plugin before sending anything upstream.

1. Make sure your configuration is in line with the latest version of this
   document.
2. Enable debug mode (see below) and check the output of your source(s). If
   the CLI program is not properly configured or is otherwise not running as
   expected, that's an issue with the program, not null-ls.
3. Check the documentation for available configuration options that might solve
   your issue.
4. If you're having trouble configuring null-ls or want to know how to achieve a
   specific result, open a discussion.
5. If you believe the issue is with null-ls itself or you want to request a new
   feature, open an issue and provide the information requested in the issue
   template.

### How do I format files?

null-ls formatters run when you call `vim.lsp.buf.formatting()` or
`vim.lsp.buf.formatting_sync()`. If a source supports it, you can run range
formatting by visually selecting part of the buffer and calling
`vim.lsp.buf.range_formatting()`.

On 0.8, you should use `vim.lsp.buf.format` (see the help file for usage
instructions).

### How do I format files on save?

See [this wiki
page](https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Formatting-on-save).

### How do I stop Neovim from asking me which server I want to use for formatting?

See [this wiki page](https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Avoiding-LSP-formatting-conflicts).

### How do I view project-level diagnostics?

For a built-in solution, use `:lua vim.diagnostic.setqflist()`. You can also
use a plugin like [trouble.nvim](https://github.com/folke/trouble.nvim).

### How do I enable debug mode and get debug output?

1. Set `debug` flag to `true` in your config:

   ```lua
   require("null-ls").setup({
       debug = true
   })
   ```

2. Use `:NullLsLog` to open your debug log in the current Neovim instance or
   `:NullLsInfo` to get the path to your debug log.

As with LSP logging, debug mode will slow down Neovim. Make sure to disable the
option after you've collected the information you're looking for.

### Does it work with (other plugin)?

In most cases, yes. null-ls tries to act like an actual LSP server as much as
possible, so it should work seamlessly with most LSP-related plugins. If you run
into problems, please try to determine which plugin is causing them and open an
issue.

[This wiki
page](https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Compatibility-with-other-plugins)
mentions plugins that require specific configuration options / tweaks to work
with null-ls.

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

### I am seeing a formatting `timeout` error message

This issue occurs when a formatter takes longer than the default timeout value.
This is an automatic mechanism and controlled by Neovim. You might want to
increase the timeout in your call:

```lua
-- 0.7
vim.lsp.buf.formatting_sync(nil, 2000) -- 2 seconds

-- 0.8
vim.lsp.buf.format({ timeout_ms = 2000 })
```

## Tests

The test suite includes unit and integration tests and depends on plenary.nvim.
Run `make test` in the root of the project to run the suite or
`FILE=filename_spec.lua make test-file` to test an individual file.

All tests expect the latest Neovim master.

## Alternatives

- [efm-langserver](https://github.com/mattn/efm-langserver) and
  [diagnostic-languageserver](https://github.com/iamcco/diagnostic-languageserver):
  general-purpose language servers that can provide formatting and diagnostics
  from CLI output.

- [nvim-lint](https://github.com/mfussenegger/nvim-lint): a Lua plugin that
  focuses on providing diagnostics from CLI output.

- [formatter.nvim](https://github.com/mhartington/formatter.nvim): a Lua plugin
  that (surprise) focuses on formatting.

## Sponsors

Thanks to everyone who sponsors my projects and makes continued development /
maintenance possible!

<!-- sponsors --><a href="https://github.com/yutkat"><img src="https://github.com/yutkat.png" width="60px" alt="" /></a><a href="https://github.com/hituzi-no-sippo"><img src="https://github.com/hituzi-no-sippo.png" width="60px" alt="" /></a><a href="https://github.com/sbc64"><img src="https://github.com/sbc64.png" width="60px" alt="" /></a><a href="https://github.com/milanglacier"><img src="https://github.com/milanglacier.png" width="60px" alt="" /></a><!-- sponsors -->
