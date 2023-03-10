local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "bslint",
    meta = {
        url = "https://github.com/rokucommunity/bslint",
        description = "A brighterscript CLI tool to lint your code without compiling your project.",
    },
    method = DIAGNOSTICS,
    filetypes = { "brs" },
    generator_opts = {
        command = "bslint",
        args = { "--files", "$FILENAME" },
        to_stdin = false,
        from_stderr = true,
        to_temp_file = true,
        format = "raw",
        on_output = function(params, done)
            local output = params.output
            if not output then
                return done()
            end

            local diagnostics = {}
            local severity = {
                error = 1,
                warning = 2,
                info = 3,
                hint = 4,
            }

            for _, line in ipairs(vim.split(output, "\n")) do
                if line ~= "" then
                    local filename, row, col, err, code, message =
                        line:match("(.*):(%d+):(%d+) %- (%a+) ([%a%d]+): (.*)")
                    if message ~= nil then
                        table.insert(diagnostics, {
                            filename = filename,
                            row = row,
                            col = col,
                            code = code,
                            source = "bslint",
                            message = message,
                            severity = severity[err],
                        })
                    end
                end
            end
            done(diagnostics)
        end,
    },
    factory = h.generator_factory,
})
