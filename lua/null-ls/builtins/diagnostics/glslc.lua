local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

return h.make_builtin({
    name = "glslc",
    meta = {
        url = "https://github.com/google/shaderc",
        description = "Shader to SPIR-V compiler.",
        notes = {
            [[The shader stage can be extracted from the file extension (`.vert`, `.geom`, `.frag`, etc.), but note that these file extensions are at the time of writing not natively recognized to be glsl files (only `.glsl` is). The shader stage can also be extracted from the file contents by adding a `#pragma shader_stage(<stage>)`. For more information see `man glslc`.]],
            [[the `--target-env` can be specified in `extra_args`. Defaults to vulkan1.0. Check `man glslc` for more possible targets environments.]],
        },
        usage = [[
local sources = {
    null_ls.builtins.diagnostics.glslc.with({
        extra_args = { "--target-env=opengl" }, -- use opengl instead of vulkan1.0
    }),
}]],
    },
    method = DIAGNOSTICS,
    filetypes = { "glsl" },
    generator_opts = {
        command = "glslc",
        to_temp_file = true,
        from_stderr = true,
        args = {
            "-o",
            "-",
            "$FILENAME",
        },
        format = "line",
        on_output = h.diagnostics.from_patterns({
            -- glslc errors (don't show the tempfile in message)
            {
                pattern = [[glslc: (%l+): .+: (.+)]],
                groups = { "severity", "message" },
            },
            -- line diagnostics
            {
                pattern = [[([^:]+):(%d+): (%l+): (.+)]],
                groups = { "filename", "row", "severity", "message" },
            },
            -- file diagnostics
            {
                pattern = [[([^:]+): (%l+): (.+)]],
                groups = { "filename", "severity", "message" },
            },
        }),
    },
    factory = h.generator_factory,
})
