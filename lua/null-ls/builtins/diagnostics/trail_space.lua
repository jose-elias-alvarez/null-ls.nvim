local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS
local SEVERITIES = h.diagnostics.severities

return h.make_builtin({
    name = "trail-space",
    meta = {
        description = "Uses inbuilt Lua code to detect lines with trailing whitespace and show a diagnostic warning on each line where it's present.",
    },
    method = DIAGNOSTICS,
    filetypes = {},
    generator = {
        fn = function(params)
            local result = {}
            local regex = vim.regex("\\s\\+$")

            for line_number = 1, #params.content do
                local line = params.content[line_number]
                local start_byte, end_byte = regex:match_str(line)

                if start_byte ~= nil then
                    table.insert(result, {
                        message = "trailing whitespace",
                        severity = SEVERITIES.warning,
                        row = line_number,
                        col = start_byte + 1,
                        end_row = line_number,
                        end_col = end_byte + 1,
                        source = "trail-space",
                    })
                end
            end

            return result
        end,
    },
})
