local c = require("null-ls.config")
local log = require("null-ls.logger")
local methods = require("null-ls.methods")
local s = require("null-ls.state")
local sources = require("null-ls.sources")
local u = require("null-ls.utils")

local api = vim.api
local lsp = vim.lsp

local client, id

local should_attach = function(bufnr)
    if api.nvim_buf_get_option(bufnr, "buftype") ~= "" or api.nvim_buf_get_name(bufnr) == "" then
        return false
    end

    if c.get().should_attach and not c.get().should_attach(bufnr) then
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

local on_init = function(new_client, initialize_result)
    local capability_is_disabled = function(method)
        -- TODO: extract map to prevent future issues
        local required_capability = lsp._request_name_to_capability[method]
        return not required_capability
            or vim.tbl_get(new_client.server_capabilities, unpack(required_capability)) == false
    end

    -- null-ls broadcasts all capabilities on launch, so this lets us have finer control
    new_client.supports_method = function(method)
        -- allow users to specifically disable capabilities
        if capability_is_disabled(method) then
            return false
        end

        -- determine capability by ability to run for the current buffer
        local internal_method = methods.map[method]
        if internal_method then
            return require("null-ls.generators").can_run(vim.bo.filetype, internal_method)
        end

        -- return true for supported methods w/o a corresponding internal method (init, shutdown)
        return methods.lsp[method] ~= nil
    end

    if c.get().on_init then
        c.get().on_init(new_client, initialize_result)
    end
    client = new_client
end

local on_exit = function(...)
    if c.get().on_exit then
        c.get().on_exit(...)
    end
    client = nil
    id = nil
end

local M = {}

M.start_client = function(fname)
    local config = {
        name = "null-ls",
        root_dir = c.get().root_dir(fname) or vim.loop.cwd(),
        on_init = on_init,
        on_exit = on_exit,
        cmd = require("null-ls.rpc").start, -- pass callback to create rpc client
        filetypes = require("null-ls.sources").get_filetypes(),
        flags = { debounce_text_changes = c.get().debounce },
        on_attach = vim.schedule_wrap(function(_, bufnr)
            if bufnr == api.nvim_get_current_buf() then
                M.setup_buffer(bufnr)
            elseif api.nvim_buf_is_valid(bufnr) then
                api.nvim_create_autocmd("BufEnter", {
                    buffer = bufnr,
                    once = true,
                    callback = function()
                        M.setup_buffer(bufnr)
                    end,
                })
            end
        end),
    }

    log:trace("starting null-ls client")
    id = lsp.start_client(config)

    if not id then
        log:error(string.format("failed to start null-ls client with config: %s", vim.inspect(config)))
    end

    return id
end

M.try_add = function(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    if not should_attach(bufnr) then
        return false
    end

    id = id or M.start_client(api.nvim_buf_get_name(bufnr))
    if not id then
        return
    end

    local did_attach = lsp.buf_is_attached(bufnr, id) or lsp.buf_attach_client(bufnr, id)
    if not did_attach then
        log:warn(string.format("failed to attach buffer %d", bufnr))
    end

    return did_attach
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

M.get_offset_encoding = function()
    return client and client.offset_encoding or "utf-16"
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

M.update_filetypes = function()
    if not client then
        return
    end

    client.config.filetypes = require("null-ls.sources").get_filetypes()
end

M.on_source_change = vim.schedule_wrap(function()
    local current_bufnr = api.nvim_get_current_buf()

    u.buf.for_each_bufnr(function(bufnr)
        if bufnr == current_bufnr then
            M.retry_add(bufnr)

            -- if in named buffer, we can register conditional sources immediately
            -- we need to check only for normal buffers, excluding nofile and terminals
            local buftype = api.nvim_buf_get_option(bufnr, "buftype")
            local bufname = api.nvim_buf_get_name(bufnr)
            if s.has_conditional_sources() and bufname ~= "" and buftype == "" then
                s.register_conditional_sources()
            end
        else
            api.nvim_create_autocmd("BufEnter", {
                buffer = bufnr,
                once = true,
                callback = function()
                    M.retry_add(bufnr)
                end,
            })
        end
    end)

    -- if conditional sources remain, check on next (named) buffer read event
    if s.has_conditional_sources() then
        api.nvim_create_autocmd("BufRead", {
            once = true,
            callback = function()
                s.register_conditional_sources()
            end,
        })
    end
end)

M.retry_add = function(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()

    local did_attach = M.try_add(bufnr)
    if did_attach then
        -- send synthetic didOpen notification to regenerate diagnostics
        M.notify_client(methods.lsp.DID_OPEN, {
            textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        })
    end
end

M.send_progress_notification = function(token, opts)
    local client_id = id -- copy into closure to avoid race condition
    if not client_id then
        return
    end

    local handler = M.resolve_handler("$/progress")
    if not handler then
        return
    end

    vim.schedule(function()
        handler(nil, {
            token = token,
            value = {
                kind = opts.kind,
                title = opts.title,
                percentage = opts.percentage,
                message = opts.message,
            },
        }, {
            client_id = client_id,
        })
    end)
end

M._reset = function()
    client = nil
    id = nil
end

return M
