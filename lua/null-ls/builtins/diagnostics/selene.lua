local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "selene",
    meta = {
        url = "https://kampfkarren.github.io/selene/",
        description = "Command line tool designed to help write correct and idiomatic Lua code.",
    },
    method = DIAGNOSTICS,
    filetypes = { "lua", "luau" },
    generator_opts = {
        command = "selene",
        args = { "--display-style", "quiet", "-" },
        to_stdin = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = h.diagnostics.from_pattern(
            [[(%d+):(%d+): (%w+)%[([%w_]+)%]: ([`]*([%w_]+)[`]*.*)]],
            { "row", "col", "severity", "code", "message", "_quote" },
            { adapters = { h.diagnostics.adapters.end_col.from_quote } }
        ),
        cwd = h.cache.by_bufnr(function(params)
            -- https://kampfkarren.github.io/selene/usage/configuration.html
            return u.root_pattern("selene.toml")(params.bufname)
        end),
    },
    factory = h.generator_factory,
})
