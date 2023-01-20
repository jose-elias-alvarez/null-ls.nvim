local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local u = require("null-ls.utils")
local is_windows = vim.loop.os_uname().version:match("Windows")
local path_separator = is_windows and "\\" or "/"

-- try get file from project, if not exists try global
local function get_executable()
  local exec_name = "phpstan";
  local exec = u.get_root() .. path_separator .. "vendor" .. path_separator .. "bin" .. path_separator .. exec_name
  local file = io.open(exec, "r")
  if file~=nil then io.close(file)
    return exec
  else
    return exec_name
  end
end


return h.make_builtin({
    name = "phpstan",
    meta = {
        url = "https://github.com/phpstan/phpstan",
        description = "PHP static analysis tool.",
        notes = {
            "Requires a valid `phpstan.neon` at root.",
            "If in place validation is required set `method` to `diagnostics_on_save` and `to_temp_file` to `false`",
        },
    },
    method = DIAGNOSTICS,
    filetypes = { "php" },
    generator_opts = {
        command = get_executable(),
        args = { "analyze", "--error-format", "json", "--no-progress", "$FILENAME" },
        format = "json_raw",
        to_temp_file = true,
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(params)
            local path = params.temp_path or params.bufname
            local parser = h.diagnostics.from_json({})
            params.messages = params.output
                    and params.output.files
                    and params.output.files[path]
                    and params.output.files[path].messages
                or {}

            return parser({ output = params.messages })
        end,
    },
    factory = h.generator_factory,
})
