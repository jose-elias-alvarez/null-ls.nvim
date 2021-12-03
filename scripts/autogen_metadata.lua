local write_file = require("null-ls.loop").write_file
local join_paths = require("null-ls.utils").join_paths

package.loaded["null-ls.builtins._meta.diagnostics"] = nil
package.loaded["null-ls.builtins._meta.formatters"] = nil
local linters = require("null-ls.builtins._meta.diagnostics")
local formatters = require("null-ls.builtins._meta.formatters")

local generated_dir = join_paths(vim.fn.getcwd(), "lua", "null-ls", "builtins", "_meta")
local metadata_file = join_paths(generated_dir, "filetype_map.lua")

vim.fn.mkdir(generated_dir, "p")

do
    local filetypes_map = {}
    for name, entry in pairs(linters) do
        for _, ft in ipairs(entry.filetypes or {}) do
            filetypes_map[ft] = filetypes_map[ft] or {}
            if filetypes_map[ft] and filetypes_map[ft].linters then
                table.insert(filetypes_map[ft].linters, name)
            else
                filetypes_map[ft]["linters"] = { name }
            end
        end
    end
    for name, entry in pairs(formatters) do
        for _, ft in ipairs(entry.filetypes or {}) do
            filetypes_map[ft] = filetypes_map[ft] or {}
            if filetypes_map[ft] and filetypes_map[ft].formatters then
                table.insert(filetypes_map[ft].formatters, name)
            else
                filetypes_map[ft]["formatters"] = { name }
            end
        end
    end

    local data = table.concat({
        "-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.",
        "-- stylua: ignore",
        "return " .. vim.inspect(filetypes_map),
    }, "\n")
    write_file(metadata_file, data, "w")
end
