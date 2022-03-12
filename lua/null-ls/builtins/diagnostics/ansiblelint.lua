local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "ansiblelint",
    meta = {
        url = "https://github.com/ansible-community/ansible-lint",
        description = "Linter for Ansible playbooks, roles and collections.",
    },
    method = DIAGNOSTICS,
    filetypes = { "yaml.ansible" },
    generator_opts = {
        command = "ansible-lint",
        to_stdin = true,
        ignore_stderr = true,
        args = { "-f", "codeclimate", "-q", "--nocolor", "$FILENAME" },
        format = "json",
        check_exit_code = function(code)
            return code <= 2
        end,
        multiple_files = true,
        on_output = function(params)
            local severities = {
                blocker = h.diagnostics.severities.error,
                critical = h.diagnostics.severities.error,
                major = h.diagnostics.severities.error,
                minor = h.diagnostics.severities.warning,
                info = h.diagnostics.severities.information,
            }
            params.messages = {}
            for _, message in ipairs(params.output) do
                local col = nil
                local row = message.location.lines.begin
                if type(row) == "table" then
                    row = row.line
                    col = row.column
                end
                table.insert(params.messages, {
                    row = row,
                    col = col,
                    message = message.check_name,
                    severity = severities[message.severity],
                    filename = message.location.path,
                })
            end
            return params.messages
        end,
    },
    factory = h.generator_factory,
})
