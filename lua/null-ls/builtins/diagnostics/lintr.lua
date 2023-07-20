local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS
local handle_lintr_output = function(params)
    local parser = h.diagnostics.from_json({
        attributes = {
            row = "line",
            col = "column",
            end_col = "endColumn",
            message = "message",
            filename = "filename",
        },
        severities = {
            ["style"] = 4,
            ["warning"] = 2,
            ["error"] = 1,
        },
    })
    local offenses = {}
    for _, offense in ipairs(params.output) do
        table.insert(offenses, {
            line = offense.line_number,
            column = offense.ranges[1][1],
            level = offense.type,
            message = offense.message,
            endColumn = offense.ranges[1][2],
            filename = offense.filename,
        })
    end
    return parser({ output = offenses })
end

return h.make_builtin({
    name = "lintr",
    meta = {
        url = "https://github.com/r-lib/lintr",
        description = "provides static code analysis for R code.",
        notes = {
            "requires lintr and jsonlite packages installed on R",
        },
    },
    method = DIAGNOSTICS,
    filetypes = { "r", "Rmd", "qmd", "quarto", "RMarkdown" },
    generator_opts = {
        command = "R",
        to_temp_file = true,
        args = {
            "--slave",
            "--vanilla",
            "-e",
            [[lintr::lint(file='$FILENAME')|>jsonlite::toJSON(force=TRUE,auto_unbox=TRUE)]],
        },
        format = "json",
        on_output = handle_lintr_output,
    },
    factory = h.generator_factory,
})
