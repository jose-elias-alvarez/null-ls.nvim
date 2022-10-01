---@diagnostic disable: undefined-global, unused-function, unused-local
local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local DIAGNOSTICS = methods.internal.DIAGNOSTICS

---Checks if a line is the start of a diagnostic's message or not.
---@param line string
---@return boolean
local function message_start(line)
    local symbols = { error = "✖", warn = "⚠", hint = "ⓘ", info = "⧗" }
    if line == nil then
        return false
    end

    local line_start = line:sub(1, 3)
    for _, v in pairs(symbols) do
        if line_start == v then
            return true
        end
    end

    return false
end

---From a message token, finds its severity
---@param message string
local function severity(message)
    local severities = {
        ["✖"] = h.diagnostics.severities.warning,
        ["⚠"] = h.diagnostics.severities.error,
        ["ⓘ"] = h.diagnostics.severities.hint,
        ["⧗"] = h.diagnostics.severities.information,
    }
    for pattern, kind in pairs(severities) do
        if pattern:sub(1, 3) == message:sub(1, 3) then
            return kind
        end
    end
end

---Lexes @commitlint/cli's raw output into single messages that can later be categorized by severity.
---@param output string
---@return string[]
local function lex(output)
    ---@type string[]: Non-empty string array.
    local lines = vim.tbl_filter(function(s)
        return s ~= "" and true or false
    end, vim.split(output, "\n"))

    ---@type string[]: Array of diagnostic messages.
    local messages = {}
    for i = 1, #lines do
        local message = ""
        local curr_line = lines[i]
        if message_start(curr_line) then
            message = message .. curr_line
            --- Go to next line, but only do anything if we're on the same message, else, go back up
            i = i + 1
            while not message_start(lines[i]) and lines[i] ~= nil do
                message = message
                    .. "\n" -- keep message formatting
                    .. lines[i]
                i = i + 1
            end
        end

        table.insert(messages, message)
    end

    return messages
end

---@param params {}
---@param done function
local function on_output(params, done)
    if type(params.output) ~= "string" then
        return done()
    end

    local diagnostics = {}

    local messages = lex(params.output)
    for i = 1, #messages do
        local message = messages[i]
        local diagnostic = {
            row = 1,
            col = 1,
            source = "commitlint",
            message = message:match("%s%s%s(.*)") or "",
            filename = "COMMIT_MESSAGE",
            severity = severity(message),
        }
        table.insert(diagnostics, diagnostic)
    end

    return done(diagnostics)
end

return h.make_builtin({
    name = "commitlint",
    meta = {
        url = "https://commitlint.js.org",
        description = "commitlint checks if your commit messages meet the conventional commit format.",
    },
    method = DIAGNOSTICS,
    filetypes = { "gitcommit" },
    generator_opts = {
        command = "commitlint",
        args = { "--edit", "$FILENAME" },
        to_temp_file = true,
        format = "raw",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = on_output,
    },
    factory = h.generator_factory,
})
