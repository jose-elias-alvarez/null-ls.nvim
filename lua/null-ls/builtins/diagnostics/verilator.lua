local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "verilator",
    meta = {
        url = "https://www.veripool.org/verilator/",
        description = "Verilog and SystemVerilog linter power by Verilator",
    },
    method = DIAGNOSTICS,
    filetypes = { "verilog", "systemverilog" },
    generator_opts = {
        command = "verilator",
        args = {
            "-lint-only",
            "-Wno-fatal",
            "$FILENAME",
        },
        from_stderr = true,
        format = "line",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(line, params)
            local path = params.bufname
            local pattern = [[%%(%w+).*]] .. path .. [[:(%d+):(%d+): (.*)]]
            local overrides = {
                severities = {
                    ["Error"] = 1,
                    ["Warning"] = 2,
                },
            }
            return h.diagnostics.from_pattern(pattern, { "severity", "row", "col", "message" }, overrides)(line, params)
        end,
    },
    factory = h.generator_factory,
})
