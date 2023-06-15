local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "typos",
    meta = {
        url = "https://github.com/crate-ci/typos",
        description = "Source code spell checker written in Rust.",
    },
    method = DIAGNOSTICS,
    filetypes = {},
    generator_opts = {
        command = "typos",
        args = {
            "--format",
            "json",
            "$FILENAME",
        },
        to_stdin = true,
        format = "line",
        check_exit_code = function(code)
            return code == 2
        end,
        on_output = function(line, params)
            local ok, decoded = pcall(vim.json.decode, line)
            if not ok then
                return
            end

            local typo = decoded.typo
            local col = decoded.byte_offset + 1
            local corrections = decoded.corrections
            local message = "`" .. typo .. "` should be "

            for _, correction in ipairs(corrections) do
                message = message .. "`" .. correction .. "`, "
            end

            return {
                row = decoded.line_num,
                col = col,
                end_col = col + typo:len(),
                message = message:gsub(", $", ""),
                severity = h.diagnostics.severities.error,
                -- Custom data for the code action builtin
                user_data = { corrections = corrections },
            }
        end,
    },
    factory = h.generator_factory,
})
