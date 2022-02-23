# Formatting

The null-ls formatting API is analogous to Neovim's LSP formatting API and
provides the following methods, exposed under the main `require("null-ls")`
module.

```lua
local null_ls = require("null-ls")

null-ls.formatting(options)
null-ls.formatting_sync(options, timeout_ms)
null-ls.range_formatting(options, start_pos, end_pos)
```

## `null-ls.formatting(options)`

Analogous to `vim.lsp.buf.formatting`. Accepts the following arguments:

- `options` (table, optional): See `:help vim.lsp.buf.formatting`. Note that as
  of now, null-ls does not recognize these options.

  null-ls accepts an extra option, `options.fallback_to_lsp` (boolean), which will
  automatically call `vim.lsp.buf.formatting(options)` if null-ls formatting is
  unavailable.

## `null-ls.formatting_sync(options, timeout_ms)`

Analogous to `vim.lsp.buf.formatting`. Accepts the following arguments:

- `options` (table, optional): See `:help vim.lsp.buf.formatting_sync`. Note
  that as of now, null-ls does not recognize these options.

  null-ls accepts an extra option, `options.fallback_to_lsp` (boolean), which
  will automatically call `vim.lsp.buf.formatting_sync(options, timeout_ms)` if
  null-ls formatting is unavailable.

- `timeout_ms` (number, optional): See `:help vim.lsp.buf.formatting_sync`. Note
  that as of now, null-ls does not recognize this option (timeouts are
  source-specific, as described in [SOURCES](./SOURCES.md).

## `null-ls.range_formatting(options, start_pos, end_pos)`

Analogous to `vim.lsp.buf.range_formatting`. Accepts the following arguments:

- `options` (table, optional): See `:help vim.lsp.buf.range_formatting`. Note
  that as of now, null-ls does not recognize these options.

  null-ls accepts an extra option, `options.fallback_to_lsp` (boolean), which
  will automatically call `vim.lsp.buf.range_formatting(options, start_pos, end_pos)` if null-ls formatting is unavailable.

- `start_pos` (number, optional): See `:help vim.lsp.buf.range_formatting`.
  Defaults to the start of the last visual selection.
- `end_pos` (number, optional): See `:help vim.lsp.buf.range_formatting`.
  Defaults to the end of the last visual selection.

## Custom formatting

### Chaining

The API methods described above return `false` if null-ls is unable to format
the current buffer. This makes it possible to fall back to another formatting
source if null-ls is unavailable, as in this example:

```lua
local custom_formatting = function()
    if not require("null-ls").formatting_sync() then
      -- fallback
    end
end
```

### Manual requests

For advanced use cases, you can manually send requests to the null-ls client:

```lua
local manual_formatting = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local client = require("null-ls.client").get_client()
    if not client then
        return
    end

    local params = vim.lsp.util.make_formatting_params()
    -- note that the method must correspond to an internal formatting method
    client.request(require("null-ls").methods.FORMATTING, params, function(err, res)
        if err then
            -- handle error
        elseif res then
            -- handle response
        end
    end, bufnr)
end
```
