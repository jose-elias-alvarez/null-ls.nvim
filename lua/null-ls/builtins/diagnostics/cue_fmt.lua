local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "cue_fmt",
    meta = {
        url = "https://github.com/cue-lang/cue",
        description = "Reports on formatting errors in .cue language files.",
    },
    method = DIAGNOSTICS,
    filetypes = { "cue" },
    generator_opts = {
        command = "cue",
        args = { "vet", "$FILENAME" },
        format = "raw",
        from_stderr = true,
        to_temp_file = true,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(params, done)
            local diagnostics = {}
            local lines = vim.split(params.output or "", "\n")

            for i, err in ipairs(lines) do
                if i % 2 == 0 then
                    local row, col = string.match(err, ".*:(%d+):(%d+)")

                    table.insert(diagnostics, {
                        row = row,
                        col = col,
                        end_col = col + 1,
                        source = "cue_fmt",
                        message = lines[i - 1],
                        severity = 1,
                    })
                end
            end

            done(diagnostics)
        end,
    },
    factory = h.generator_factory,
})
