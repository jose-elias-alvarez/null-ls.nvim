local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

return h.make_builtin({
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "prolog" },
    generator_opts = {
        command = "swipl",
        args = { "-q", "-t", "halt(1)", "-s", "$FILENAME" },
        format = "raw",
        check_exit_code = function(code)
            return code <= 1
        end,
        on_output = function(params, done)
            local diagnostics = {}
            local lines = vim.fn.split(params.err, "\r\n\\|\r\\|\n")
            local err = false
            local warning = false
            local row = 0
            local col = 0
            local msg = ""
            local i = 1
            if lines[1]:match("v:null") then
                done(diagnostics)
                return
            end
            while i <= #lines do
                local line = lines[i]
                if err then
                    local _, _, m = line:find("^ERROR:    (.*)")
                    if m then
                        msg = msg .. m
                        i = i + 1
                    else
                        err = false
                        table.insert(diagnostics, {
                            row = row,
                            col = col,
                            source = "swipl",
                            message = msg,
                            severity = 1,
                        })
                    end
                elseif warning then
                    local _, _, m = line:find("^Warning:    (.*)")
                    if m then
                        msg = msg .. m
                        i = i + 1
                    else
                        warning = false
                        table.insert(diagnostics, {
                            row = row,
                            col = col,
                            source = "swipl",
                            message = msg,
                            severity = 2,
                        })
                    end
                else
                    local _
                    i = i + 1
                    _, _, row, msg = line:find("^Warning:.-:(%d+):%s*(.*)")
                    warning = msg ~= nil
                    _, _, row, msg = line:find("^ERROR:.-:(%d+):%s*(.*)")
                    err = msg ~= nil
                end
            end
            if err or warning then
                table.insert(diagnostics, {
                    row = row,
                    col = col,
                    source = "swipl",
                    message = msg,
                    severity = err and 1 or 2,
                })
            end
            done(diagnostics)
        end,
    },
    factory = h.generator_factory,
})
