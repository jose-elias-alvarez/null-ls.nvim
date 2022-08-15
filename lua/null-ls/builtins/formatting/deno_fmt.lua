local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

local extensions = {
    javascript = "js",
    javascriptreact = "jsx",
    json = "json",
    jsonc = "jsonc",
    markdown = "md",
    typescript = "ts",
    typescriptreact = "tsx",
}

return h.make_builtin({
    name = "deno_fmt",
    meta = {
        url = "https://deno.land/manual/tools/formatter",
        description = "Use [Deno](https://deno.land/) to format TypeScript, JavaScript/JSON and markdown.",
        notes = {
            "`deno fmt` supports formatting JS/X, TS/X, JSON and markdown. If you only want deno to format a subset of these filetypes you can overwrite these with `.with({filetypes={}}`)",
        },
        usage = [[
local sources = {
    null_ls.builtins.formatting.deno_fmt, -- will use the source for all supported file types
    null_ls.builtins.formatting.deno_fmt.with({
		filetypes = { "markdown" }, -- only runs `deno fmt` for markdown
    }),
}]],
    },
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "json",
        "jsonc",
        "markdown",
        "typescript",
        "typescriptreact",
    },
    generator_opts = {
        command = "deno",
        args = function(params)
            return { "fmt", "-", "--ext", extensions[params.ft] }
        end,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
