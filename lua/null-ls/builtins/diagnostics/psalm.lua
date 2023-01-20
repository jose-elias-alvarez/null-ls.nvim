local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local u = require("null-ls.utils")
local is_windows = vim.loop.os_uname().version:match("Windows")
local path_separator = is_windows and "\\" or "/"

-- executable search in the project, if there is no search in the global scope
local function get_executable()
  local exec_name = "psalm"
  local exec = u.get_root() .. path_separator .. "vendor" .. path_separator .. "bin" .. path_separator .. exec_name
  local file = io.open(exec, "r")
  if file ~= nil then io.close(file)
    return exec
  else
    return exec_name
  end
end

return h.make_builtin({
    name = "psalm",
    meta = {
        url = "https://psalm.dev/",
        description = "A static analysis tool for finding errors in PHP applications.",
    },
    method = DIAGNOSTICS,
    filetypes = { "php" },
    generator_opts = {
        command = get_executable(),
        args = { "--output-format=json", "--no-progress", "$FILENAME" },
        format = "json_raw",
        from_stderr = true,
        to_temp_file = true,
        check_exit_code = function(code)
            return code <= 1
        end,

        on_output = h.diagnostics.from_json({
            attributes = {
                severity = "severity",
                row = "line_from",
                end_row = "line_to",
                col = "column_from",
                end_col = "column_to",
                code = "shortcode",
            },
            severities = {
                info = h.diagnostics.severities["information"],
                error = h.diagnostics.severities["error"],
            },
        }),
    },
    factory = h.generator_factory,
})
