local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

return h.make_builtin({
    name = "prettierd",
    meta = {
        url = "https://github.com/fsouza/prettierd",
        description = "prettier, as a daemon, for ludicrous formatting speed.",
    },
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "css",
        "scss",
        "less",
        "html",
        "json",
        "jsonc",
        "yaml",
        "markdown",
        "markdown.mdx",
        "graphql",
        "handlebars",
    },
    generator_opts = {
        command = "prettierd",
        args = function(params)
            if params.method == FORMATTING then
                return { "$FILENAME" }
            end

            local row, end_row = params.range.row - 1, params.range.end_row - 1
            local col, end_col = params.range.col - 1, params.range.end_col - 1
            local start_offset = vim.api.nvim_buf_get_offset(params.bufnr, row) + col
            local end_offset = vim.api.nvim_buf_get_offset(params.bufnr, end_row) + end_col

            return { "$FILENAME", "--range-start=" .. start_offset, "--range-end=" .. end_offset }
        end,
        dynamic_command = cmd_resolver.from_node_modules(),
        to_stdin = true,
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern(
                -- https://prettier.io/docs/en/configuration.html
                ".prettierrc",
                ".prettierrc.json",
                ".prettierrc.yml",
                ".prettierrc.yaml",
                ".prettierrc.json5",
                ".prettierrc.js",
                ".prettierrc.cjs",
                ".prettierrc.toml",
                "prettier.config.js",
                "prettier.config.cjs",
                "package.json"
            )(params.bufname)
        end),
    },
    factory = h.formatter_factory,
})
