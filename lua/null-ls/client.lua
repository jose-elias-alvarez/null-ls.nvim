local c = require("null-ls.config")
local methods = require("null-ls.methods")
local sources = require("null-ls.sources")
local u = require("null-ls.utils")

local api = vim.api
local client

local should_attach = function(bufnr)
    local all_sources = sources.get_all()
    -- don't attach if no sources have been registered
    if vim.tbl_isempty(all_sources) then
        return false
    end

    -- be paranoid and try to make sure that the buffer represents an actual file
    if api.nvim_buf_get_option(bufnr, "buftype") ~= "" or api.nvim_buf_get_name(bufnr) == "" then
        return false
    end

    local ft = api.nvim_buf_get_option(bufnr, "filetype")
    for _, source in ipairs(all_sources) do
        if sources.is_available(source, ft) then
            return true
        end
    end

    return false
end

local on_init = function(new_client)
    new_client.supports_method = function(method)
        local internal_method = methods.map[method]
        if internal_method then
            return require("null-ls.generators").can_run(vim.bo.filetype, internal_method)
        end

        return methods.lsp[method] ~= nil
    end

    client = new_client
end

local on_exit = function()
    client = nil
end

local start_client = function(fname)
    return vim.lsp.start_client({
        name = "null-ls",
        root_dir = u.root_pattern(".null-ls-root", "Makefile", ".git")(fname) or vim.loop.cwd(),
        on_init = on_init,
        on_exit = on_exit,
        cmd = c.get().cmd,
        flags = { debounce_text_changes = c.get().debounce },
        on_attach = c.get().on_attach,
    })
end

local M = {}

M.start_client = start_client

M.try_add = function(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    if not should_attach(bufnr) then
        return
    end

    local id = client and client.id or start_client(api.nvim_buf_get_name(bufnr))
    vim.lsp.buf_attach_client(bufnr, id)
end

M.get_client = function()
    return client
end

M.notify_client = function(method, params)
    if not client then
        return
    end

    client.notify(method, params)
end

M.resolve_handler = function(method)
    return client and client.handlers[method] or vim.lsp.handlers[method]
end

M._reset = function()
    client = nil
end

return M
