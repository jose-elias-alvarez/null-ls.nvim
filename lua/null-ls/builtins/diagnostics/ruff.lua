local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local DIAGNOSTICS = methods.internal.DIAGNOSTICS
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
        elseif code == "R001" then
            pattern = [[Class %`(.*)%` inherits from object]]
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
            "$FILENAME",
        },
        format = "line",
        check_exit_code = function(code)
            return code == 0
        end,
        to_stdin = false,
        from_stderr = true,
        to_temp_file = true,
        on_output = h.diagnostics.from_pattern(
            [[(%d+):(%d+): ((%u)%w+) (.*)]],
            { "row", "col", "code", "severity", "message" },
            {
                adapters = {
                    custom_end_col,
                },
                severities = {
                    E = h.diagnostics.severities["error"],
                    F = h.diagnostics.severities["warning"],
                    R = h.diagnostics.severities["error"],
                },
            }
        ),
    },
    factory = h.generator_factory,
})
