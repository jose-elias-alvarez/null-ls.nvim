local b = require("null-ls.builtins")
local u = require("null-ls.utils")

local is_directory = function(path)
    local stat = vim.loop.fs_stat(path)
    return stat and stat.type == "directory" or false
end

local write_file = require("null-ls.loop").write_file
local join_paths = u.path.join

local null_ls_dir = vim.fn.getcwd()
local builtins_dir = join_paths(null_ls_dir, "lua", "null-ls", "builtins")
local generated_dir = join_paths(builtins_dir, "_meta")

vim.fn.mkdir(generated_dir, "p")

local metadata_files = {
    ft_mappings = join_paths(generated_dir, "filetype_map.lua"),
}

local methods = {}
local filetypes_map = {}

local table_gen = function(data)
    return table.concat({
        "-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.",
        "-- stylua: ignore",
        "return " .. vim.inspect(data),
        "",
    }, "\n")
end

do
    for _, entry in ipairs(vim.fn.glob(builtins_dir .. "/*", 1, 1)) do
        if not entry:match("_") and is_directory(entry) then
            local method = entry:gsub(".*/", "")
            table.insert(methods, method)
            table.sort(methods)
            metadata_files[method] = join_paths(generated_dir, method .. ".lua")
        end
    end

    for _, method in ipairs(methods) do
        local method_dir = join_paths(builtins_dir, method)
        local method_pattern = method_dir .. "/*.lua"
        local sources = {}
        for _, filename in ipairs(vim.fn.glob(method_pattern, 1, 1)) do
            local source_name = filename:gsub(".*/", ""):gsub("%.lua$", "")
            local source = b[method][source_name]
            if source then
                sources[source_name] = { filetypes = source.filetypes or {} }
                for _, ft in ipairs(source.filetypes or {}) do
                    filetypes_map[ft] = filetypes_map[ft] or {}
                    if filetypes_map[ft] and filetypes_map[ft][method] then
                        table.insert(filetypes_map[ft][method], source_name)
                        table.sort(filetypes_map[ft])
                        table.sort(filetypes_map[ft][method])
                    else
                        filetypes_map[ft][method] = { source_name }
                    end
                end
            end
        end

        write_file(metadata_files[method], table_gen(sources), "w")
    end

    write_file(metadata_files.ft_mappings, table_gen(filetypes_map), "w")
end
