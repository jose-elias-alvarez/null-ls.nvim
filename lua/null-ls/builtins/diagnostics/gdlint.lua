local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "gdlint",
    meta = {
        url = "",
        description = "",
    },
    method = DIAGNOSTICS,
    filetypes = { "gdscript" },
    generator_opts = {
        command = "gdlint",
        args = { "$FILENAME" },
        from_stderr = true,
        -- ignore_stderr = true,
        format = "line",
        --      check_exit_code = function(code)
        -- print("we are out")
        -- return code > 0
        --      end,
        on_output = h.diagnostics.from_patterns({
            {
                pattern = [[:(%d+): (.*)]],
                groups = { "row", "message" },
                -- overrides = {
                --     diagnostic = { severity = INFO },
                --     offsets = { col = 1 },
                -- },
            },
        }),
    },
    factory = h.generator_factory,
})
