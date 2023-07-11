local h = require("null-ls.helpers")
local u = require("null-ls.utils")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "isortd",
    meta = {
        url = "https://github.com/urm8/isortd",
        description = "isortd is a small HTTP server that exposes isort’s functionality over a simple protocol. The main benefit of using it is to avoid the cost of starting up a new isort process every time you want to format a file.",
        config = {
            {
                key = "hostname",
                type = "string",
                description = "Address that the isortd server listens on. Defaults to localhost.",
            },
            {
                key = "port",
                type = "string",
                description = "Port that the isortd server listens on. Defaults to 47393.",
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
            local port = config.port or 47393
            local root = u.get_root()
            local filepath = vim.api.nvim_buf_get_name(params.bufnr)
            require("plenary.curl").post(hostname .. ":" .. port, {
                body = table.concat(params.content, "\n"),
                headers = {
                    ["XX-SRC"] = root,
                    ["XX-PATH"] = filepath,
                },
                callback = function(response)
                    if response.status == 200 then
                        return done({ { text = response.body } })
                    else
                        local log = require("null-ls.logger")
                        log:error(string.format("error formatting with isortd %s %s", response.status, response.body))
                    end
                    return done()
                end,
            })
        end,
    },
})
