local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "styler",
    meta = {
        url = "https://github.com/r-lib/styler",
        description = "Non-invasive pretty printing of R code.",
    },
    method = FORMATTING,
    filetypes = { "r", "rmd" },
    generator_opts = {
        command = "R",
        args = function(params)
            local default_args = {
                "--slave",
                "--no-restore",
                "--no-save",
                "-e",
            }
            if params.ft == "r" then
                return vim.list_extend(default_args, {
                    [[con=file("stdin");output=styler::style_text(readLines(con));close(con);print(output, colored=FALSE)]],
                })
            end
            return vim.list_extend(default_args, {
                string.format(
                    [[options(styler.quiet = TRUE)
                          con = file("stdin")
                          temp = tempfile("styler",fileext = ".%s")
                          writeLines(readLines(con), temp)
                          styler::style_file(temp)
                          cat(paste0(readLines(temp), collapse = '\n'))
                          close(con)
                        ]],
                    params.ft
                ),
            })
        end,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
