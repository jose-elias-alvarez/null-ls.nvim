-- THIS SCRIPT RUNS AUTOMATICALLY. DO NOT MANUALLY RUN IT

-- imports
local builtins = require("null-ls.builtins")
local u = require("null-ls.utils")

-- shared
local methods = {}

-- utils
local is_directory = function(path)
    local stat = vim.loop.fs_stat(path)
    return stat and stat.type == "directory" or false
end
local write_file = require("null-ls.loop").write_file
local join_paths = u.path.join

-- constants
local NULL_LS_DIR = vim.loop.cwd()
local BUILTINS_DIR = join_paths(NULL_LS_DIR, "lua", "null-ls", "builtins")
local META_DIR = join_paths(BUILTINS_DIR, "_meta")
local DOC_FILE = join_paths(NULL_LS_DIR, "doc", "BUILTINS.md")
local BUILTINS_URL_TEMPLATE =
    "https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/lua/null-ls/builtins/%s/%s.lua"

-- metadata
local sources = {}
local filetypes = {}
-- contains paths to metadata files for each method
local metadata_files = {
    ft_map = join_paths(META_DIR, "filetype_map.lua"),
}

-- helpers
local generate_meta_table = function(data)
    return table.concat({
        "-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.",
        "-- stylua: ignore",
        "return " .. vim.inspect(data),
        "",
    }, "\n")
end

local generate_source_metadata = function(source, method, name)
    -- use deepcopy to resolve references when `source.with()` is used
    local source_filetypes = type(source.filetypes) and vim.deepcopy(source.filetypes) or {}
    sources[method][name] = { filetypes = source_filetypes }

    for _, ft in ipairs(source.filetypes) do
        filetypes[ft] = filetypes[ft] or {}
        if filetypes[ft] and filetypes[ft][method] then
            table.insert(filetypes[ft][method], name)
            table.sort(filetypes[ft][method])
        else
            filetypes[ft][method] = { name }
        end
    end
end

-- docs
local markdown_content = {}

-- helpers
local generate_method_header = function(method)
    local header = { "##" }
    for _, component in ipairs(vim.split(method, "_")) do
        table.insert(header, component:sub(1, 1):upper() .. component:sub(2))
    end
    vim.list_extend(markdown_content, { "", table.concat(header, " ") })
end

local generate_repo_url = function(method, name)
    return string.format(BUILTINS_URL_TEMPLATE, method, name)
end

local generate_builtin_header = function(source, name)
    local url = source.meta and source.meta.url
    return {
        url and string.format("### [%s](%s)", name, url) or string.format("### %s", name),
    }
end

local generate_builtin_description = function(source)
    return source.meta.description and {
        "",
        source.meta.description,
    } or {}
end

local generate_builtin_usage = function(source, method, name)
    return {
        "",
        "#### Usage",
        "",
        "```lua",
        source.meta.usage or string.format("local sources = { null_ls.builtins.%s.%s }", method, name),
        "```",
    }
end

local generate_builtin_defaults = function(source, method, name)
    local defaults = {
        "",
        "#### Defaults",
        "",
        string.format("- Filetypes: `%s`", vim.inspect(source.filetypes)),
    }

    local source_methods = type(source.method) == "table" and source.method or { source.method }
    local methods_string = {}
    for _, source_method in ipairs(source_methods) do
        table.insert(methods_string, require("null-ls.methods").get_readable_name(source_method))
    end
    vim.list_extend(defaults, {
        string.format("- %s: `%s`", #source_methods > 1 and "Methods" or "Method", table.concat(methods_string, ", ")),
    })

    local generator = source.generator
    local opts = generator.opts
    if opts then
        local command, args = opts.command, opts.args

        if command then
            local command_content
            if type(command) == "string" then
                command_content = string.format("`%s`", command)
            else
                command_content = string.format(
                    "dynamically resolved (see [source](%s))",
                    generate_repo_url(method, name)
                )
            end
            vim.list_extend(defaults, {
                "- Command: " .. command_content,
            })
        end

        if args then
            local args_content
            if type(args) == "table" then
                args_content = string.format("`%s`", vim.inspect(args))
            else
                args_content = string.format("dynamically resolved (see [source](%s))", generate_repo_url(method, name))
            end
            vim.list_extend(defaults, {
                "- Args: " .. args_content,
            })
        end
    end

    return defaults
end

local generate_builtin_notes = function(source)
    if not source.meta.notes or vim.tbl_isempty(source.meta.notes) then
        return {}
    end

    local notes = {
        "",
        "#### Notes",
        "",
    }
    for _, note in ipairs(source.meta.notes) do
        table.insert(notes, "- " .. note)
    end
    return notes
end

local generate_builtin_content = function(source, method, name)
    local content = { "" }
    vim.list_extend(content, generate_builtin_header(source, name))
    vim.list_extend(content, generate_builtin_description(source))
    vim.list_extend(content, generate_builtin_usage(source, method, name))
    vim.list_extend(content, generate_builtin_defaults(source, method, name))
    vim.list_extend(content, generate_builtin_notes(source))

    vim.list_extend(markdown_content, content)
end

local generate_documentation = function()
    -- final newline
    table.insert(markdown_content, "")
    return table.concat(
        vim.list_extend({
            "<!-- THIS FILE IS AUTOMATICALLY GENERATED. DO NOT EDIT IT MANUALLY -->",
            "",
            "# Built-in Sources",
            "",
            "This is an automatically generated list of all null-ls built-in sources.",
            "",
            "See [BUILTIN_CONFIG](BUILTIN_CONFIG.md) to learn how to set up and configure these sources.",
        }, markdown_content),
        "\n"
    )
end

-- main
do
    -- get methods from builtin dir folder structure
    for _, entry in ipairs(vim.fn.glob(BUILTINS_DIR .. "/*", 1, 1)) do
        if is_directory(entry) then
            local method = entry:gsub(".*/", "")
            -- ignore internal
            if method:sub(1, 1) ~= "_" then
                table.insert(methods, method)
                metadata_files[method] = join_paths(META_DIR, method .. ".lua")
                sources[method] = {}
            end
        end
    end
    table.sort(methods)

    -- load and handle builtins in each method dir
    for _, method in ipairs(methods) do
        generate_method_header(method)
        local method_dir = join_paths(BUILTINS_DIR, method)
        local method_pattern = method_dir .. "/*.lua"
        -- sort order is not guaranteed, so ensure it here
        local files = vim.fn.glob(method_pattern, 1, 1)
        table.sort(files, function(a, b)
            return a:upper() < b:upper()
        end)

        for _, filename in ipairs(files) do
            local name = filename:gsub(".*/", ""):gsub("%.lua$", "")
            local source = builtins[method][name]
            if not source then
                string.format("failed to load builtin %s for method %s", name, method)
            else
                generate_source_metadata(source, method, name)
                generate_builtin_content(source, method, name)
            end
        end

        write_file(metadata_files[method], generate_meta_table(sources[method]), "w")
    end

    write_file(metadata_files.ft_map, generate_meta_table(filetypes), "w")
    write_file(DOC_FILE, generate_documentation(), "w")
end
