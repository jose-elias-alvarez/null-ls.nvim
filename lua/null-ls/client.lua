local c = require("null-ls.config")
local log = require("null-ls.logger")
local methods = require("null-ls.methods")
local sources = require("null-ls.sources")
local u = require("null-ls.utils")

local api = vim.api
local lsp = vim.lsp

local client, id

local should_attach = function(bufnr)
    -- try to make sure the buffer represents an actual file
    if api.nvim_buf_get_option(bufnr, "buftype") ~= "" or api.nvim_buf_get_name(bufnr) == "" then
        return false
    end

    -- buf_attach_client handles this case, but this lets us avoid unnecessary checks
    if id and lsp.buf_is_attached(bufnr, id) then
        return false
    end

    local ft = api.nvim_buf_get_option(bufnr, "filetype")
    for _, source in ipairs(sources.get_all()) do
        if sources.is_available(source, ft) then
            return true
        end
    end

    return false
end

local on_init = function(new_client)
    -- null-ls broadcasts all capabilities on launch, so this lets us have finer control
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
    id = nil
end

local M = {}

M.start_client = function(fname)
    require("null-ls.rpc").setup()

    local config = {
        name = "null-ls",
        root_dir = u.root_pattern(".null-ls-root", "Makefile", ".git")(fname) or vim.loop.cwd(),
        on_init = on_init,
        on_exit = on_exit,
        cmd = c.get().cmd,
        flags = { debounce_text_changes = c.get().debounce },
        on_attach = vim.schedule_wrap(function(_, bufnr)
            if bufnr == api.nvim_get_current_buf() then
                M.setup_buffer(bufnr)
            else
                -- defer setup until BufEnter
                vim.cmd(
                    string.format(
                        [[autocmd BufEnter <buffer=%d> ++once unsilent lua require("null-ls.client").setup_buffer(%d)]],
                        bufnr,
                        bufnr
                    )
                )
            end
        end),
    }

    log:trace("starting null-ls client")
    id = lsp.start_client(config)

    if not id then
        log:error(string.format("failed to start null-ls client with config: %s", vim.inspect(config)))
    end
end

M.try_add = function(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    if not should_attach(bufnr) then
        return
    end

    if not id then
        M.start_client(api.nvim_buf_get_name(bufnr))
    end

    local did_attach = lsp.buf_attach_client(bufnr, id)
    if not did_attach then
        log:warn(string.format("failed to attach buffer %d", bufnr))
    end
end

M.setup_buffer = function(bufnr)
    if not client then
        log:debug(string.format("unable to set up buffer %d (client not active)", bufnr))
        return
    end

    local on_attach = c.get().on_attach
    if on_attach then
        on_attach(client, bufnr)
    end
end

M.get_id = function()
    return id
end

M.get_client = function()
    return client
end

M.notify_client = function(method, params)
    if not client then
        log:debug(
            string.format("unable to notify client for method %s (client not active): %s", method, vim.inspect(params))
        )
        return
    end

    client.notify(method, params)
end

M.resolve_handler = function(method)
    return client and client.handlers[method] or lsp.handlers[method]
end

M._reset = function()
    client = nil
    id = nil
end

return M
