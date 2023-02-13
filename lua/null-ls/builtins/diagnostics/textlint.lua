local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local handle_output = function(params)
    params.messages = params.output and params.output[1] and params.output[1].messages or {}
    if params.err then
        table.insert(params.messages, { message = params.err })
    end

    local parser = h.diagnostics.from_json({
        attributes = {
            severity = "severity",
        },
        severities = {
            h.diagnostics.severities["warning"],
            h.diagnostics.severities["error"],
        },
    })

    return parser({ output = params.messages })
end

return h.make_builtin({
    name = "textlint",
    meta = {
        url = "https://github.com/textlint/textlint",
        description = "The pluggable linting tool for text and Markdown.",
    },
    method = DIAGNOSTICS,
    filetypes = { "txt", "markdown" },
    generator_opts = {
        command = "textlint",
        to_stdin = true,
        args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" },
        format = "json_raw",
        check_exit_code = { 0, 1 },
        on_output = handle_output,
        dynamic_command = cmd_resolver.from_node_modules(),
        cwd = h.cache.by_bufnr(function(params)
            return u.root_pattern(
                -- https://textlint.github.io/docs/configuring.html
                ".textlintrc",
                ".textlintrc.js",
                ".textlintrc.json",
                ".textlintrc.yml",
                ".textlintrc.yaml",
                "package.json"
            )(params.bufname)
        end),
    },
    factory = h.generator_factory,
})
