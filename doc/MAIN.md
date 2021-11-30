<!-- markdownlint-configure-file
{
  "line-length": false
}
-->

# null-ls Documentation

Splits into the following documents:

- [MAIN](MAIN.md) (this document), which describes general concepts and
  implementation details

- [CONFIG](CONFIG.md), which describes the available configuration
  options

- [BUILTINS](BUILTINS.md), which describes how to use and make built-in
  sources

- [SOURCES](SOURCES.md), which describes the source API

- [HELPERS](HELPERS.md), which describes available helpers and how to use
  them to make new sources

- [TESTING](TESTING.md), which describes best practices for testing null-ls
  integrations

## Sources

The basic unit of null-ls operation is a **source**.

Each source must have a **method**, which defines when it runs, a **generator**,
which runs in response to a request matching the source's method, and a list of
**filetypes**, which determines when the method is active.

To see a list of active sources for the current buffer in a human-readable
format, use the command `:NullLsInfo`.

You can also programatically get the same information using the Lua method
`require("null-ls.info").get_active_sources()`, which returns a table where each
key is a null-ls method (see below) and each value is a list containing the name
of each active source.

Sources must be
**registered**, either by the user or by an integration, before they are active.

Sources can also define a **name**, which allows integrations to see if sources
null-ls has already registered their sources to prevent duplicate registration.

The document describes methods, filetypes, registration, and names below.
It describes generators separately in the [generators](#generators) section.

### Methods

null-ls methods are analogous to LSP methods, but the plugin uses internal
methods to avoid collisions. The safest way to use methods in a source
definition is by referencing the `methods` object.

```lua
local null_ls = require("null-ls")

local my_source = {}
-- source will run on LSP code action request
my_source.method = null_ls.methods.CODE_ACTION

-- source will run on LSP diagnostics request
my_source.method = null_ls.methods.DIAGNOSTICS

-- source will run on LSP formatting request
my_source.method = null_ls.methods.FORMATTING

-- source will run on LSP hover request
my_source.method = null_ls.methods.HOVER

-- source will run on LSP completion request
my_source.method = null_ls.methods.completion
```

### Filetypes

A source has a list of filetypes, which define when the source is active. The
list can contain a single filetype, more than one filetype, or nothing,
which indicates that the source should activate for all filetypes.

```lua
local my_source = {}

-- single
my_source.filetypes = { "lua" }

-- more than one
my_source.filetypes = { "lua", "teal" }

-- all filetypes
my_source.filetypes = {}
```

Sources can also include a list of `disabled_filetypes`. null-ls checks these
first, so they'll supersede any defined filetypes.

### Registration

null-ls can register sources via the `config` method (intended for a user's
configuration) or via the `register` method (intended for integrations or
advanced use cases).

```lua
local null_ls = require("null-ls")

-- using config method
null_ls.config({ sources = my_sources })

-- using register method
null_ls.register({ my_sources })
```

Both options accept a single source, a list of sources, or a table containing
more than one source with shared configuration.

```lua
local null_ls = require("null-ls")

-- single source
null_ls.register({ my_source })

-- list of sources with independent configuration
null_ls.register({ my_source, my_other_source })

-- more than one source with shared configuration
null_ls.register({ name = "my-sources", filetypes = { "lua" }, sources = { my_source, my_other_source } })
```

Note that dynamically registering a diagnostic source will refresh diagnostics
for buffers affected by the new source.

### Names

null-ls optionally saves source names to prevent duplicate registration. This
means integrations can call `register()` any number of times without worrying
about duplicate registration.

```lua
local null_ls = require("null-ls")

-- registered
null_ls.register({ name = "my-sources", ... })

-- not registered
null_ls.register({ name = "my-sources", ... })
```

null-ls also exposes a method, `is_registered()`, that returns a
boolean value indicating whether it has already registered a source.

```lua
local null_ls = require("null-ls")

local name = "my_sources"
print(null_ls.is_registered(name)) -- false

null_ls.register({ name = "my-sources", ... })
print(null_ls.is_registered(name)) -- true
```

## Generators

null-ls generators define what a source provides when it receives a request that
matches its method. Generators must define the key-value pair `fn`, which is the
callback that runs when null-ls calls the source.

A generator's `fn` is schedule-wrapped, making it safe to call any API function.
It's also wrapped to handle errors, meaning it'll catch errors thrown from
within `fn` and show them to the user as warnings.

```lua
local my_source = {}

my_source.generator = {
    fn = function(params)
        return {
            {
                col = 1,
                row = 1,
                message = "There is something wrong with this file!",
                severity = 1,
                source = "my-source",
            },
        }
    end,
}
```

For convenience, all generator functions have access to a `params` table as
their first argument, which contains information about the current file and
editor state.

```lua
local params = {
    content, -- current buffer content (table, split at newline)
    lsp_method, -- lsp method that triggered request (string)
    method, -- null-ls method that triggered generator (string)
    row, -- cursor's current row (number, zero-indexed)
    col, -- cursor's current column (number)
    bufnr, -- current buffer's number (number)
    bufname, -- current buffer's full path (string)
    ft, -- current buffer's filetype (string)
    root, -- current buffer's root directory (string)
}
```

### Asynchronous Generators

Setting `async = true` inside a generator will run it as an asynchronous
generator. Asynchronous generators have access to a `done()` callback as their
second argument. Processing will pause until all async generators have called
`done()`, either with `nil` or a list of results.

```lua
local my_source = {}

my_source.generator = {
    -- must be explictly set
    async = true,
    fn = function(params, done)
        -- always return done() to prevent timeouts
        if not string.match(params.content, "something wrong") then
            return done()
        end

        -- return results as normal inside the done() callback
        my_async_function(params, function()
            return done({
                {
                    col = 1,
                    row = 1,
                    message = "There is something wrong with this file!",
                    severity = 1,
                    source = "my-source",
                },
            })
        end)
    end,
}
```

### `on_run`

If defined, a generator's `on_run` callback runs when the generator runs (before
it returns results). `on_run` receives `params` as its first argument, so it can
react to or alter state before continuing to the handler:

```lua
local my_source = {
    generator = {
        on_run = function(params)
            params.multiple_files = true
        end,
    },
}
```

### Generator Return Types

Generators must return `nil` or a list containing their results. The structure
of each item in the list varies depending on the null-ls method that invoked the
generator.

All return values are **required** unless specified as optional.

#### Code actions

```lua
return { {
    title, -- string
    action, -- function (callback with no arguments)
} }
```

Once generated, null-ls stores code action results in its internal state and
calls them if selected by the user. It clears and re-generates non-selected
actions on the next request.

Like generator functions, code action callbacks are schedule-wrapped, making it
safe to call any API function.

#### Diagnostics

```lua
-- null-ls assumes ranges are 1-indexed, so sources should offset if not
return { {
    row, -- number, optional (defaults to first line)
    col, -- number, optional (defaults to beginning of line)
    end_row, -- number, optional (defaults to row)
    end_col, -- number, optional (defaults to end of line),
    source, -- string, optional (defaults to "null-ls")
    code, -- number, optional
    message, -- string
    severity, -- 1 (error), 2 (warning), 3 (information), 4 (hint)
    filename, -- string, optional (requires params.multiple_files)
    bufnr, -- number, optional (requires params.multiple_files)
} }
```

null-ls generates diagnostics in response to LSP notifications and publishes
them via the `vim.diagnostic` API when available (falling back to the LSP
handler on pre-0.6 versions).

When `params.multiple_files` is true, specifying `filename` or `bufnr` publishes
diagnostics to the specified buffer. Otherwise, null-ls publishes diagnostics to
the buffer that triggered the LSP diagnostic (in most cases the active buffer).

#### Formatting

```lua
return { {
    row, -- number, optional (see diagnostics for defaults)
    col, -- number, optional
    end_row, -- number, optional
    end_col, -- number, optional
    text, -- string
} }
```

null-ls applies formatting results to the matching buffer and, depending on the
user's settings, will optionally write the buffer.

Users can register an arbitrary number of formatters for a single filetype. To
match expected behavior, formatters run _sequentially_ in the order in which the
user has registered them (manually or via an integration).

#### Range Formatting

Same as formatting.

Note that getting range-formatted output requires converting the visually
selected range into the required format and modifying the spawn arguments
accordingly. See `range_formatting_args_factory` in [HELPERS](HELPERS.md) for an
example of how null-ls handles this for built-in
sources.

#### Hover

```lua
return { "First line", "Second line", "And so on" }
```

Hover sources should return a list of plaintext strings, where each element
represents a single line.

null-ls will combine the results of each of its hover sources when calling the
handler, so 2+ _null-ls_ hover sources are okay, but note that running more than
one LSP server with hover capabilities **is not well-supported** (by default,
the second popup will wipe out the first).

#### Completion

```lua
return {
    {
        items = { label = "Item #1", insertText = "Item #1", documentation = "A test completion item" },
        isIncomplete = true,
    },
}
```

Completion sources must return a
[CompletionList](https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#completionList).
You can leverage the full attributes of `CompletionItem` from the LSP
specification. Other plugins (e.g completion plugins) can then use these
attributes to provide more context about the highlighted completion item.
