local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local DIAGNOSTICS_ON_SAVE = methods.internal.DIAGNOSTICS_ON_SAVE

local get_severity = function(severity)
    if severity == "error" then
        return h.diagnostics.severities.error
    elseif severity == "warning" then
        return h.diagnostics.severities.warning
    elseif severity == "note" or severity == "remark" then
        return h.diagnostics.severities.information
    end
    return h.diagnostics.severities.warning
end

return h.make_builtin({
    name = "clazy",
    meta = {
        url = "https://github.com/KDE/clazy",
        description = "Qt-oriented static code analyzer based on the Clang framework",
        notes = {
            [[`clazy` needs a compilation database (`compile_commands.json`) to work. By default `clazy` will search for a compilation database in all parent folders of the input file.]],
            [[If the compilation database is not in a parent folder, the `-p` option can be used to point to the corresponding folder (e.g. the projects build directory):
```lua
local sources = {
    null_ls.builtins.diagnostics.clazy.with({
        extra_args = { "-p=$ROOT/build" },
    }),
}
```]],
            [[Alternatively, `compile_commands.json` can be linked into the project's root directory. For more information see https://clang.llvm.org/docs/HowToSetupToolingForLLVM.html]],
            [[`clazy` will be run only when files are saved to disk, so that `compile_commands.json` can be used.]],
        },
    },
    method = DIAGNOSTICS_ON_SAVE,
    filetypes = { "cpp" },
    generator_opts = {
        command = "clazy-standalone",
        args = {
            "--ignore-included-files",
            "--header-filter=$ROOT/.*",
            "$FILENAME",
        },
        format = "line",
        to_stdin = false,
        from_stderr = true,
        on_output = function(line, params)
            if not vim.startswith(line, params.bufname) then
                return
            end

            local row, col, sev, msg = string.match(line, "[^:]+:(%d+):(%d+): (%w+): (.*)$")
            return {
                row = row,
                col = col,
                source = "clazy",
                message = msg,
                severity = get_severity(sev),
            }
        end,
        check_exit_code = function(code)
            return code <= 1
        end,
    },
    factory = h.generator_factory,
})
