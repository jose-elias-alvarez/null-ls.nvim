local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "vcom",
    meta = {
        url = "https://eda.sw.siemens.com/en-US/ic/modelsim/",
        description = "Adds support for Mentor Graphics Questa/ModelSim `vcom` VHDL compiler/checker",
        notes = "If you want the work directory to be in the current working directory, remove '-work' and '/tmp/vcom_work' from the args list",
    },
    method = DIAGNOSTICS,
    filetypes = { "vhdl" },
    generator_opts = {
        command = "vcom",
        args = { "-2008", "-quiet", "-lint", "-work", "/tmp/vcom_work", "$FILENAME" },
        to_stdin = false,
        to_temp_file = true,
        from_stderr = true,
        format = "line",
        on_output = h.diagnostics.from_pattern(
        [[^**%s(%w+):[%a%d%s%.-_/]+%((%d+)%):%s+(.+)]],
        {"severity", "row", "message" },
        {
            severities = {
                E = h.diagnostics.severities["Error"],
                W = h.diagnostics.severities["Warning"],
            },
        }
        ),
    },
    factory = h.generator_factory,
})
