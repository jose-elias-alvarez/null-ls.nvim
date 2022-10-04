local null_ls = require("null-ls")
local h = require("null-ls.helpers")

return h.make_builtin({
    name = "phpmd",
    meta = {
        url = "https://github.com/phpmd/phpmd/",
        description = "Runs PHP Mess Detector against PHP files.",
    },
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = { "php" },
    generator_opts = {
        command = "phpmd",
        args = { "$FILENAME", "json" },
        format = "raw",
        to_temp_file = true,
        check_exit_code = function(code)
            return code <= 3
        end,
        on_output = function(params, done)
            local output, err = params.output, params.err

            if err then
                return done({ { message = "phpmd error: cannot analyze this file" } })
            end

            local ok, parsed = pcall(vim.json.decode, output)

            if not ok then
                return done({ { message = "phpmd error: cannot parse output as JSON." } })
            end

            local parser = h.diagnostics.from_json({
                attributes = {
                    message = "description",
                    severity = "priority",
                    row = "beginLine",
                    end_row = "endLine",
                    code = "rule",
                },
                severities = {
                    [1] = h.diagnostics.severities["error"],
                    [2] = h.diagnostics.severities["warning"],
                    [3] = h.diagnostics.severities["information"],
                    [4] = h.diagnostics.severities["hint"],
                    [5] = h.diagnostics.severities["hint"],
                },
            })

            params.violations = parsed and parsed.files and parsed.files[1] and parsed.files[1].violations or {}

            done(parser({ output = params.violations }))
        end,
    },
    factory = h.generator_factory,
})
