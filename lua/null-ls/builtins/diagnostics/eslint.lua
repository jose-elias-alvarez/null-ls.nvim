local h = require("null-ls.helpers")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local add_rule_id_to_messages = function(messages)
  if not messages then
    return
  end

  for _, message in ipairs(messages) do
    if message.ruleId then
      message.message = message.message .. " [" .. message.ruleId .. "]"
    end
  end
end

local handle_eslint_output = function(params)
    params.messages = params.output and params.output[1] and params.output[1].messages or {}
    if params.err then
        table.insert(params.messages, { message = params.err })
    end

    local parser = h.diagnostics.from_json({
        attributes = {
            severity = "severity",
        },
        severities = {
            h.diagnostics.severities["warning"],
            h.diagnostics.severities["error"],
        },
    })

    add_rule_id_to_messages(params.messages)

    return parser({ output = params.messages })
end

return h.make_builtin({
    name = "eslint",
    meta = {
        url = "https://github.com/eslint/eslint",
        description = "A linter for the JavaScript ecosystem.",
    },
    method = DIAGNOSTICS,
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
    generator_opts = {
        command = "eslint",
        args = { "-f", "json", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        format = "json_raw",
        check_exit_code = function(code)
            return code <= 1
        end,
        use_cache = true,
        on_output = handle_eslint_output,
        dynamic_command = cmd_resolver.from_node_modules,
    },
    factory = h.generator_factory,
})
