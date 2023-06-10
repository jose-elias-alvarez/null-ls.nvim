local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local format_message = function(typo, corrections)
    local message = "`" .. typo .. "` should be "

    local numCorrections = #corrections

    for i, correction in ipairs(corrections) do
        message = message .. "`" .. correction .. "`"

        if i == numCorrections - 1 then
            message = message .. " or "
        elseif i < numCorrections then
            message = message .. ", "
        end
    end

    message = message .. "."

    return message
end

local handle_typos_output = function(line)
    -- Sample error format from typos-cli
    -- {
    --   "type": "typo",
    --   "path": "-",
    --   "line_num": 1,
    --   "byte_offset": 6,
    --   "typo": "ther",
    --   "corrections": [
    --     "there",
    --     "their",
    --     "the",
    --     "other"
    --   ]
    -- }

    local ok, err = pcall(vim.json.decode, line)
    if not ok then
        return
    end

    local severity = vim.diagnostic.severity.WARN
    local typo = err.typo
    local row = err.line_num
    local col = err.byte_offset + 1
    local corrections = err.corrections

    return {
        message = format_message(typo, corrections),
        severity = severity,
        row = row,
        col = col,
        end_col = col + typo:len(),
        end_row = row,
        source = "Typos",
        -- Custom data for the code action builtin
        user_data = { corrections = corrections },
    }
end

return h.make_builtin({
    name = "typos",
    meta = {
        url = "https://github.com/crate-ci/typos",
        description = "Source code spell checker written in rust",
    },
    method = DIAGNOSTICS,
    filetypes = {},
    generator_opts = {
        command = "typos",
        args = { "--format", "json", "-" },
        to_stdin = true,
        format = "line",
        check_exit_code = function(code)
            return code == 2
        end,
        use_cache = true,
        on_output = handle_typos_output,
    },
    factory = h.generator_factory,
})
