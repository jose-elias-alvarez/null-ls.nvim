local h = require("null-ls.helpers")
local utils = require("null-ls.utils")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "actionlint",
    meta = {
        url = "https://github.com/rhysd/actionlint",
        description = "Actionlint is a static checker for GitHub Actions workflow files.",
    },
    method = DIAGNOSTICS,
    filetypes = { "yaml" },
    generator_opts = {
        command = "actionlint",
        args = h.cache.by_bufnr(function(params)
            local default_args = { "-no-color", "-format", "{{json .}}" }

            -- actionlint ignores config files when reading from stdin
            -- unless they are explicitly passed.
            local config_file_names = vim.tbl_map(function(ext)
                return utils.path.join(".github", "actionlint." .. ext)
            end, { "yml", "yaml" })

            local config_file_path = vim.fs.find(config_file_names, {
                path = params.bufname,
                upward = true,
                stop = vim.fs.dirname(params.root),
            })[1]

            if config_file_path then
                default_args = vim.list_extend(default_args, { "-config-file", config_file_path })
            end

            return vim.list_extend(default_args, { "-" })
        end),
        format = "json",
        from_stderr = true,
        to_stdin = true,
        on_output = h.diagnostics.from_json({
            attributes = {
                message = "message",
                source = "actionlint",
                code = "kind",
                severity = 1,
            },
        }),
        runtime_condition = h.cache.by_bufnr(function(params)
            return params.bufname:find("%.github[\\/]workflows") ~= nil
        end),
    },
    factory = h.generator_factory,
})
