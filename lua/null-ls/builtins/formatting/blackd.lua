local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local curl = require("plenary.curl")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "blackd",
    meta = {
        url = "https://github.com/psf/black",
        description = "The uncompromising Python code formatter",
    },
    method = FORMATTING,
    filetypes = { "python" },
    generator = {
        fn = function(params)
            local hostname = params.options.hostname or "localhost"
            local port = params.options.port or 45484
            local response = curl.post(hostname .. ":" .. port, {
                body = table.concat(params.content, "\n"),
                headers = {
                    ["X-Line-Length"] = params.options.line_length,
                    ["X-Skip-Source-First-Line"] = params.options.skip_source_first_line and "true",
                    ["X-Skip-String-Normalization"] = params.options.skip_string_normalization and "true",
                    ["X-Skip-Magic-Trailing-Comma"] = params.options.skip_magic_trailing_comma and "true",
                    ["X-Preview"] = params.options.preview and "true",
                    ["X-Fast-Or-Safe"] = params.options.fast and "fast",
                    ["X-Python-Variant"] = params.options.python_variant,
                },
            })
            return response.status == 200 and { { text = response.body } }
        end,
    },
})
