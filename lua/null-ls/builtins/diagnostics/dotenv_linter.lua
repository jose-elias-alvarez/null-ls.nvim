local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "dotenv-linter",
    meta = {
        url = "https://github.com/dotenv-linter/dotenv-linter",
        description = "Lightning-fast linter for .env files.",
    },
    method = DIAGNOSTICS,
    filetypes = { "sh" },
    generator_opts = {
        command = "dotenv-linter",
        args = { "$FILENAME" },
        from_stderr = false,
        ignore_stderr = false,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        to_temp_file = true,
        runtime_condition = h.cache.by_bufnr(function(params)
            return params.bufname:find("%.env.*") ~= nil
        end),
        on_output = h.diagnostics.from_pattern([[%w+:(%d+) (%w+): (.*)]], { "row", "code", "message" }),
    },
    factory = h.generator_factory,
})
