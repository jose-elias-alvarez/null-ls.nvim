local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "nginx_beautifier",
    meta = {
        url = "https://github.com/vasilevich/nginxbeautifier",
        description = "Beautifies and formats nginx configuration files.",
    },
    method = FORMATTING,
    filetypes = { "nginx" },
    generator_opts = {
        command = "nginxbeautifier",
        args = { "-i", "-o", "$FILENAME" },
        to_temp_file = true,
        from_temp_file = true,
    },
    factory = h.formatter_factory,
})
