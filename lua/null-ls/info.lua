local c = require("null-ls.config")
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

    return {
        bufnr = bufnr,
        win_id = win_id,
    }
end

local function indent_lines(lines, offset)
    offset = offset or "\t"
    return vim.tbl_map(function(val)
        return offset .. val
    end, lines)
end

local function str_list(list)
    return fmt("[%s]", table.concat(list, ", "))
end

local M = {}

M.get_active_sources = function(bufnr, ft)
    bufnr = bufnr or api.nvim_get_current_buf()
    ft = ft or api.nvim_buf_get_option(bufnr, "filetype")

    local active_sources = {}
    for _, source in ipairs(require("null-ls.sources").get_available(ft)) do
        for method in pairs(source.methods) do
            active_sources[method] = active_sources[method] or {}
            table.insert(active_sources[method], source.name)
        end
    end
    return active_sources
end

M.show_window = function()
    local client = require("null-ls.client").get_client()
    local bufnr = api.nvim_get_current_buf()
    local ft = api.nvim_buf_get_option(bufnr, "filetype")
    if not client or not lsp.buf_is_attached(bufnr, client.id) then
        log:warn("failed to get info: buffer is not attached")
        return
    end

    local create_method_info = function(method)
        local name = methods.readable[method]
        local active_sources = {}
        local supported_sources = {}

        for _, source in ipairs(sources.get_available(ft, method) or {}) do
            table.insert(active_sources, source.name)
        end

        -- the metadata is indexed by the builtin-names
        for _, source in ipairs(sources.get_supported(ft, name) or {}) do
            table.insert(supported_sources, source)
        end

        local info_lines = {
            name,
            fmt("* Active: %s", str_list(active_sources)),
            fmt("* Supported: %s", str_list(supported_sources)),
            "",
        }

        vim.fn.matchadd("Type", name .. "\\ze")
        return info_lines
    end

    local create_logging_info = function()
        local info_lines = {
            "current level: " .. c.get().log.level,
            "path: " .. log:get_path(),
        }
        return info_lines
    end

    local lines = {}

    local header = {
        [[  | \ | | _   _ | || |        | |  __   ]],
        [[  | . ` || | | || || | ______ | |/ __|  ]],
        [[  | |\  || |_| || || ||______|| |\__ \  ]],
        [[  \_| \_/ \__,_||_||_|        |_||___/  ]],
    }

    local buf_info = {
        "Buffer number: " .. bufnr,
        "Detected filetype: " .. ft,
    }

    local methods_info = {}
    for method, _ in pairs(methods.readable) do
        vim.list_extend(methods_info, create_method_info(method))
    end

    local logger_header = { "Logging" }
    local logger_info = create_logging_info()

    for _, section in ipairs({
        { "" },
        header,
        { "" },
        buf_info,
        { "" },
        methods_info,
        { "" },
        logger_header,
        indent_lines(logger_info),
    }) do
        vim.list_extend(lines, indent_lines(section))
    end

    local win_info = make_window(0.8, 0.7)
    local win_bufnr, win_id = win_info.bufnr, win_info.win_id

    api.nvim_buf_set_lines(win_bufnr, 0, -1, true, lines)
    api.nvim_buf_set_option(win_bufnr, "buftype", "nofile")
    api.nvim_buf_set_option(win_bufnr, "filetype", "null-ls-info")
    api.nvim_buf_set_option(win_bufnr, "modifiable", false)

    vim.cmd([[highlight link NullLsInfoHeader Type]])
    for method, _ in pairs(methods.readable) do
        local name = methods.readable[method]
        vim.fn.matchadd("NullLsInfoHeader", name .. "\\ze")
    end

    api.nvim_buf_set_keymap(win_bufnr, "n", "<Esc>", "<cmd>bd<CR>", { noremap = true })

    vim.cmd(
        string.format("autocmd BufHidden,BufLeave <buffer> ++once lua pcall(vim.api.nvim_win_close, %d, true)", win_id)
    )
end

return M
