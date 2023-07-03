local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "blackd",
    meta = {
        url = "https://github.com/psf/black",
        description = "blackd is a small HTTP server that exposes Black’s functionality over a simple protocol. The main benefit of using it is to avoid the cost of starting up a new Black process every time you want to blacken a file. The only way to configure the formatter is by using the provided config options, it will not pick up on config files.",

        config = {
            {
                key = "hostname",
                type = "string",
                description = "Address to bind the server to. Defaults to localhost.",
            },
            { key = "port", type = "string", description = "Port to listen on. Defaults to 45484." },
            {
                key = "line_length",
                type = "number",
                description = "Set how many characters per line to allow. Defaults to 88.",
            },
            {
                key = "skip_source_first_line",
                type = "boolean",
                description = "If set to true, the first line of the source code will be ignored. Defaults to false.",
            },
            {
                key = "skip_string_normalization",
                type = "boolean",
                description = "If set to true, no string normalization will be performed. Defaults to false.",
            },
            {
                key = "skip_magic_trailing_comma",
                type = "boolean",
                description = "If set to true, trailing commas will not be used as a reason to split lines. Defaults to false.",
            },
            {
                key = "preview",
                type = "boolean",
                description = "If set to true, experimental and potentially disruptive style changes will be used. Defaults to false.",
            },
            {
                key = "fast",
                type = "boolean",
                description = "If set to true, Black will not perform an AST safety check after formatting. Defaults to false.",
            },
            {
                key = "python_variant",
                type = "string",
                description = "If set to pyi, Black will format all input files like typing stubs regardless of the file extension. Otherwise, its value must correspond to a Python version or a set of comma-separated Python versions, optionally prefixed with py. (e.g. py3.5,py3.6). Defaults to empty string.",
            },
        },
    },
    method = FORMATTING,
    filetypes = { "python" },
    generator = {
        async = true,
        fn = function(params, done)
            local config = params:get_config()
            local hostname = config.hostname or "localhost"
            local port = config.port or 45484
            require("plenary.curl").post(hostname .. ":" .. port, {
                body = table.concat(params.content, "\n"),
                headers = {
                    ["X-Line-Length"] = config.line_length or 88,
                    ["X-Skip-Source-First-Line"] = config.skip_source_first_line or nil,
                    ["X-Skip-String-Normalization"] = config.skip_string_normalization or nil,
                    ["X-Skip-Magic-Trailing-Comma"] = config.skip_magic_trailing_comma or nil,
                    ["X-Preview"] = config.preview or nil,
                    ["X-Fast-Or-Safe"] = config.fast == "fast" and "fast" or nil,
                    ["X-Python-Variant"] = config.python_variant or "",
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
