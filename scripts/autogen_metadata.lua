local f = require("null-ls.builtins").formatting
local l = require("null-ls.builtins").diagnostics
local u = require("null-ls.utils")

local write_file = require("null-ls.loop").write_file
local join_paths = u.path.join

local null_ls_dir = vim.fn.getcwd()
local builtins_dir = join_paths(null_ls_dir, "lua", "null-ls", "builtins")
local generated_dir = join_paths(builtins_dir, "_meta")

vim.fn.mkdir(generated_dir, "p")

local metadata_files = {
    ft_mappings = join_paths(generated_dir, "filetype_map.lua"),
    formatters = join_paths(generated_dir, "formatters.lua"),
    linters = join_paths(generated_dir, "linters.lua"),
}

local formatters_pattern = builtins_dir .. "/formatting/*.lua"
local linters_pattern = builtins_dir .. "/diagnostics/*.lua"

local formatters = {}
local linters = {}
local filetypes_map = {}

do
    for _, filename in ipairs(vim.fn.glob(linters_pattern, 1, 1)) do
        local source_name = filename:gsub(".*/", ""):gsub("%.lua$", "")
        local linter = l[source_name]
        if linter then
            linters[source_name] = { filetypes = linter.filetypes or {} }
            for _, ft in ipairs(linter.filetypes or {}) do
                filetypes_map[ft] = filetypes_map[ft] or {}
                if filetypes_map[ft] and filetypes_map[ft].linters then
                    table.insert(filetypes_map[ft].linters, source_name)
                else
                    filetypes_map[ft]["linters"] = { source_name }
                end
            end
        end
    end
    for _, filename in ipairs(vim.fn.glob(formatters_pattern, 1, 1)) do
        local source_name = filename:gsub(".*/", ""):gsub("%.lua$", "")
        local formatter = f[source_name]
        if formatter then
            formatters[source_name] = { filetypes = formatter.filetypes or {} }
            for _, ft in ipairs(formatter.filetypes or {}) do
                filetypes_map[ft] = filetypes_map[ft] or {}
                if filetypes_map[ft] and filetypes_map[ft].formatters then
                    table.insert(filetypes_map[ft].formatters, source_name)
                else
                    filetypes_map[ft]["formatters"] = { source_name }
                end
            end
        end
    end

    local table_gen = function(data)
        return table.concat({
            "-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.",
            "-- stylua: ignore",
            "return " .. vim.inspect(data),
        }, "\n")
    end

    write_file(metadata_files.ft_mappings, table_gen(filetypes_map), "w")
    write_file(metadata_files.formatters, table_gen(formatters), "w")
    write_file(metadata_files.linters, table_gen(linters), "w")
end
