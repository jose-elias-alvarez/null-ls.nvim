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
    generator = {
        async = true,
        fn = function(params, done)
            local config = params:get_config()
            local hostname = config.hostname or "localhost"
            local port = config.port or 45484
            curl.post(hostname .. ":" .. port, {
                body = table.concat(params.content, "\n"),
                headers = {
                    ["X-Line-Length"] = config.line_length,
                    ["X-Skip-Source-First-Line"] = config.skip_source_first_line,
                    ["X-Skip-String-Normalization"] = config.skip_string_normalization,
                    ["X-Skip-Magic-Trailing-Comma"] = config.skip_magic_trailing_comma,
                    ["X-Preview"] = config.preview,
                    ["X-Fast-Or-Safe"] = config.fast_or_safe,
                    ["X-Python-Variant"] = config.python_variant,
                },
                callback = function(response)
                    if response.status == 200 then
                        return done({ { text = response.body } })
                    end
                    return done()
                end,
            })
        end,
    },
})
