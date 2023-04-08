local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local _starts_with = function(str, start)
    return str:sub(1, #start) == start
end

local ruff_rule_severities = {
    { "ANN", 0, h.diagnostics.severities["information"] }, -- flake8-annotations
    { "COM", 0, h.diagnostics.severities["information"] }, -- flake8-commas
    { "ISC", 0, h.diagnostics.severities["error"] }, -- flake8-implicit-str-concat
    { "PIE", 0, h.diagnostics.severities["warning"] }, -- flake8-pie
    { "PGH", 0, h.diagnostics.severities["information"] }, -- pygrep-hooks
    { "PLC", 0, h.diagnostics.severities["information"] }, -- pylint conventions
    { "PLE", 0, h.diagnostics.severities["error"] }, -- pylint errors
    { "PLR", 0, h.diagnostics.severities["hint"] }, -- pylint refactors
    { "PLW", 0, h.diagnostics.severities["warning"] }, -- pylint warnings
    { "PTH", 0, h.diagnostics.severities["hint"] }, -- flake8-use-pathlib
    { "RET", 0, h.diagnostics.severities["warning"] }, -- flake8-return
    { "RUF", 0, h.diagnostics.severities["warning"] }, -- ruff-specific
    { "SIM", 0, h.diagnostics.severities["information"] }, -- flake8-simplify
    { "TRY", 0, h.diagnostics.severities["information"] }, -- tryceratops
    { "T20", 0, h.diagnostics.severities["information"] }, -- flake8-print
    { "C4", 0, h.diagnostics.severities["warning"] }, -- flake8-comprehensions
    { "EM", 0, h.diagnostics.severities["information"] }, -- flake8-errmsg
    { "UP", 0, h.diagnostics.severities["information"] }, -- pyupgrade
    { "A", 0, h.diagnostics.severities["warning"] }, -- flake8-builtins
    { "B", 0, h.diagnostics.severities["warning"] }, -- flake8-bugbear
    { "D", 0, h.diagnostics.severities["information"] }, -- pydocstyle
    { "E", 0, h.diagnostics.severities["error"] }, -- pycodestyle errors
    { "F", 0, h.diagnostics.severities["warning"] }, -- pyflakes
    { "I", 0, h.diagnostics.severities["warning"] }, -- isort
    { "S", 0, h.diagnostics.severities["warning"] }, -- flake8-bandit
    { "W", 0, h.diagnostics.severities["warning"] }, -- pycodestyle warnings
}
-- TODO: account for user-provided severities (custom mappings)
-- local user_severities = { I = "error", B904 = "error" }
-- for k, sv in pairs(user_severities) do
--     sv = h.diagnostics.severities[sv]
--     table.insert(ruff_rule_severities, {k, 1, sv})
-- end

table.sort(ruff_rule_severities, function(k1, k2)
    -- More specific (i.e., longer) codes need to be matched *first* to avoid false
    -- positives, e.g. I v.s. ISC.
    local len1 = string.len(k1[1])
    local len2 = string.len(k2[1])
    if len1 ~= len2 then
        return len1 > len2
    end

    -- Give higher priority to user-provided mappings otherwise.
    return k1[2] > k2[2]
end)

--- Assign severity based on the captured code
local custom_severity_adapter = {
    severity = function(entries, _)
        local code = entries["code"]

        for _, datum in next, ruff_rule_severities do
            local c, sv = datum[1], datum[3]
            if _starts_with(code, c) then
                return sv
            end
        end
        -- use fallback severity when `code` does not match
        return nil
    end,
}

local custom_end_col = {
    end_col = function(entries, line)
        if not line then
            return
        end

        local start_col = entries["col"]
        local message = entries["message"]
        local code = entries["code"]
        local default_position = start_col + 1

        local pattern = nil
        local trimmed_line = line:sub(start_col, -1)

        if code == "F841" or code == "F823" then
            pattern = [[Local variable %`(.*)%`]]
        elseif code == "F821" or code == "F822" then
            pattern = [[Undefined name %`(.*)%`]]
        elseif code == "F401" then
            pattern = [[%`(.*)%` imported but unused]]
        elseif code == "F841" then
            pattern = [[Local variable %`(.*)%` is assigned to but never used]]
        end
        if not pattern then
            return default_position
        end

        local results = message:match(pattern)
        local _, end_col = trimmed_line:find(results, 1, true)

        if not end_col then
            return default_position
        end

        end_col = end_col + start_col
        if end_col > tonumber(start_col) then
            return end_col
        end

        return default_position
    end,
}

return h.make_builtin({
    name = "ruff",
    meta = {
        url = "https://github.com/charliermarsh/ruff/",
        description = "An extremely fast Python linter, written in Rust.",
    },
    method = DIAGNOSTICS,
    filetypes = { "python" },
    generator_opts = {
        command = "ruff",
        args = {
            "-n",
            "-e",
            "--stdin-filename",
            "$FILENAME",
            "-",
        },
        format = "line",
        check_exit_code = function(code)
            return code == 0
        end,
        to_stdin = true,
        ignore_stderr = true,
        on_output = h.diagnostics.from_pattern([[(%d+):(%d+): (%w+) (.*)]], { "row", "col", "code", "message" }, {
            adapters = {
                custom_end_col,
                custom_severity_adapter,
            },
        }),
    },
    factory = h.generator_factory,
})
