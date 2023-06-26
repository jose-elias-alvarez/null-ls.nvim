local curl = require("plenary.curl")
local h = require("null-ls.helpers")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "blackd",
    meta = {
        url = "https://github.com/psf/black",
        description = "The uncompromising Python code formatter",
    },
    method = FORMATTING,
    filetypes = { "python" },
    factory = function(opts)
        return {
            fn = function(params)
                local options = u.handle_function_opt(opts.args)
                local hostname = options.hostname or "localhost"
                local port = options.port or 45484
                local response = curl.post(hostname .. ":" .. port, {
                    body = table.concat(params.content, "\n"),
                    headers = {
                        ["X-Line-Length"] = options.line_length,
                        ["X-Skip-Source-First-Line"] = options.skip_source_first_line,
                        ["X-Skip-String-Normalization"] = options.skip_string_normalization,
                        ["X-Skip-Magic-Trailing-Comma"] = options.skip_magic_trailing_comma,
                        ["X-Preview"] = options.preview,
                        ["X-Fast-Or-Safe"] = options.fast_or_safe,
                        ["X-Python-Variant"] = options.python_variant,
                    },
                })
                return response.status == 200 and { { text = response.body } }
            end,
        }
    end,
})
