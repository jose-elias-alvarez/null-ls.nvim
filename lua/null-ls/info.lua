local log = require("null-ls.logger")
local methods = require("null-ls.methods")
local sources = require("null-ls.sources")

local lsp = vim.lsp
local api = vim.api
local fmt = string.format

-- adapted from nvim-lspconfig's :LspInfo window
local make_window = function(height_percentage, width_percentage)
    local row_start_percentage = (1 - height_percentage) / 2
    local col_start_percentage = (1 - width_percentage) / 2

    local row = math.ceil(vim.o.lines * row_start_percentage)
    local col = math.ceil(vim.o.columns * col_start_percentage)
    local width = math.floor(vim.o.columns * width_percentage)
    local height = math.ceil(vim.o.lines * height_percentage)

    local opts = {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal",
        border = {
            { " ", "NormalFloat" },
            { " ", "NormalFloat" },
            { " ", "NormalFloat" },
            { " ", "NormalFloat" },
            { " ", "NormalFloat" },
            { " ", "NormalFloat" },
            { " ", "NormalFloat" },
            { " ", "NormalFloat" },
        },
    }

    local bufnr = api.nvim_create_buf(false, true)
    local win_id = api.nvim_open_win(bufnr, true, opts)
    api.nvim_win_set_buf(win_id, bufnr)

    vim.cmd("setlocal nocursorcolumn ts=2 sw=2")

    return bufnr, win_id
end

local function indent_lines(lines, offset)
    offset = offset or "\t"
    return vim.tbl_map(function(val)
        return offset .. val
    end, lines)
end

local function str_list(list)
    return fmt("%s", table.concat(list, " | "))
end

local M = {}

M.show_window = function()
    local client = require("null-ls.client").get_client()
    local bufnr = api.nvim_get_current_buf()
    local filetype = api.nvim_buf_get_option(bufnr, "filetype")
    local highlights = {}
    local is_attached = true
    if not client or not lsp.buf_is_attached(bufnr, client.id) then
        is_attached = false
    end

    local get_methods_per_source = function(source)
        local available_methods = vim.tbl_keys(source.methods)
        return vim.tbl_map(methods.get_readable_name, available_methods)
    end

    local get_supported_filestypes = function(source)
        local filetypes = vim.tbl_keys(source.filetypes)
        return vim.tbl_map(function(ft)
            return ft == "_all" and "*" or ft
        end, filetypes)
    end

    local create_source_info = function(source)
        local info_lines = {
            fmt("* name: %s", source.name),
            fmt("* filetypes: %s", str_list(get_supported_filestypes(source))),
            fmt("* methods: %s", str_list(get_methods_per_source(source))),
            "",
        }
        return info_lines
    end

    local create_active_sources_info = function(ft)
        local info_lines = {
            "Active source(s)",
        }

        for _, source in ipairs(sources.get_available(ft)) do
            info_lines = vim.list_extend(info_lines, create_source_info(source))
            table.insert(highlights, { "Title", "name:.*\\zs" .. source.name .. "\\ze" })
        end
        table.insert(highlights, { "Type", info_lines[1] })
        return info_lines
    end

    local create_supported_methods_info = function(ft)
        local supported_methods = sources.get_supported(ft)

        local info_lines = {
            "Supported source(s)",
        }
        -- the metadata is indexed by the builtin-names
        for method, names in pairs(supported_methods) do
            info_lines = vim.list_extend(info_lines, {
                fmt("* %s: %s", method, str_list(names)),
            })
        end

        table.insert(highlights, { "Type", info_lines[1] })
        return info_lines
    end

    local create_logging_info = function()
        local info_lines = {
            "Logging",
            "* current level: " .. log.__handle.level,
            "* path: " .. log:get_path(),
        }
        table.insert(highlights, { "Type", info_lines[1] })
        return info_lines
    end

    local lines = {}

    local header = {
        "null-ls",
        "https://github.com/jose-elias-alvarez/null-ls.nvim",
    }
    table.insert(highlights, { "Label", header[1] })

    local methods_info = create_supported_methods_info(filetype)
    local sources_info = nil
    local logger_info = nil
    if is_attached then
        sources_info = create_active_sources_info(filetype)
        logger_info = create_logging_info()
    end

    -- stylua: ignore
    for _, section in pairs({
        header,
        logger_info,
        sources_info,
        methods_info,
    }) do
        if section then
            lines = vim.list_extend(lines, indent_lines({ "" }))
            lines = vim.list_extend(lines, indent_lines(section))
        end
    end

    if not is_attached then
        local info_lines = { "* Note: current buffer has no sources attached" }
        table.insert(highlights, { "Type", info_lines[1] })

        lines = vim.list_extend(lines, indent_lines({ "" }))
        lines = vim.list_extend(lines, indent_lines(info_lines))
    end

    local win_bufnr, win_id = make_window(0.8, 0.7)

    api.nvim_buf_set_lines(win_bufnr, 0, -1, true, lines)
    api.nvim_buf_set_option(win_bufnr, "buftype", "nofile")
    api.nvim_buf_set_option(win_bufnr, "filetype", "null-ls-info")
    api.nvim_buf_set_option(win_bufnr, "modifiable", false)

    vim.cmd([[highlight link NullLsInfoHeader Type]])

    for _, hi in ipairs(highlights) do
        vim.fn.matchadd(hi[1], hi[2])
    end

    api.nvim_buf_set_keymap(win_bufnr, "n", "<Esc>", "<cmd>bd<CR>", { noremap = true })

    vim.cmd(
        string.format("autocmd BufHidden,BufLeave <buffer> ++once lua pcall(vim.api.nvim_win_close, %d, true)", win_id)
    )
end

return M
