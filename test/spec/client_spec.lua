local stub = require("luassert.stub")
local mock = require("luassert.mock")

local c = require("null-ls.config")
local methods = require("null-ls.methods")
local tu = require("null-ls.test-utils")
local u = require("null-ls.utils")

local lsp = mock(vim.lsp, true)
local sources = mock(require("null-ls.sources"), true)

describe("client", function()
    local client = require("null-ls.client")

    local mock_client_id = 1
    local mock_bufnr = 2
    local mock_filetypes = { "lua", "teal" }
    local mock_initialize_result = { capabilities = { codeActionProvider = true } }

    local mock_client
    before_each(function()
        mock_client = {
            id = mock_client_id,
            config = {},
            resolved_capabilities = {},
            server_capabilities = {},
        }
        lsp.start_client.returns(mock_client_id)
        sources.get_filetypes.returns(mock_filetypes)
    end)

    after_each(function()
        lsp.start_client:clear()
        lsp.buf_attach_client:clear()

        c.reset()
        client._reset()

        tu.wipeout()
    end)

    describe("start_client", function()
        it("should start client with options", function()
            local id = client.start_client()

            assert.equals(id, mock_client_id)
            local opts = lsp.start_client.calls[1].refs[1]
            assert.equals(opts.name, "null-ls")
            assert.equals(opts.root_dir, vim.loop.cwd())
            assert.equals(opts.cmd, c.get().cmd)
            assert.same(opts.flags, { debounce_text_changes = c.get().debounce })
            assert.truthy(type(opts.on_init) == "function")
            assert.truthy(type(opts.on_exit) == "function")
            assert.truthy(type(opts.on_attach) == "function")
            assert.equals(opts.filetypes, mock_filetypes)
        end)

        it("should use custom root_dir", function()
            local root_dir = stub.new()
            root_dir.returns("mock-root")
            c._set({ root_dir = root_dir })

            client.start_client("mock-file")

            assert.stub(root_dir).was_called_with("mock-file")
            local opts = lsp.start_client.calls[1].refs[1]
            assert.equals(opts.root_dir, "mock-root")
        end)

        it("should call user-defined on_init with new client and initialize_result", function()
            local on_init = stub.new()
            c._set({ on_init = on_init })

            client.start_client("mock-file")
            lsp.start_client.calls[1].refs[1].on_init(mock_client, mock_initialize_result)

            assert.stub(on_init).was_called_with(mock_client, mock_initialize_result)
        end)

        describe("on_exit", function()
            local on_exit
            before_each(function()
                client.start_client()
                lsp.start_client.calls[1].refs[1].on_init(mock_client)

                on_exit = lsp.start_client.calls[1].refs[1].on_exit
            end)

            it("should clear client and id", function()
                on_exit()

                assert.falsy(client.get_client())
                assert.falsy(client.get_id())
            end)

            it("should call user-defined on_exit with exit code and signal", function()
                local user_on_exit = stub.new()
                c._set({ on_exit = user_on_exit })

                on_exit(0, 0)

                assert.stub(user_on_exit).was_called_with(0, 0)
            end)
        end)

        describe("on_init", function()
            local on_init
            before_each(function()
                client.start_client()
                on_init = lsp.start_client.calls[1].refs[1].on_init
            end)

            it("should set client and override client.supports_method", function()
                on_init(mock_client)

                assert.equals(client.get_client(), mock_client)
                assert.truthy(mock_client.supports_method)
            end)

            describe("supports_method", function()
                local can_run = stub(require("null-ls.generators"), "can_run")
                local has = stub(u, "has_version")

                local supports_method
                before_each(function()
                    on_init(mock_client)
                    supports_method = mock_client.supports_method
                end)
                after_each(function()
                    can_run.returns(nil)
                    can_run:clear()
                end)

                it("should return result of generators.can_run if method has corresponding internal method", function()
                    can_run.returns(true)
                    local is_supported = supports_method(methods.lsp.CODE_ACTION)

                    assert.stub(can_run).was_called_with(vim.bo.filetype, methods.internal.CODE_ACTION)
                    assert.equals(is_supported, true)
                end)

                it("should return result of methods.is_supported if no corresponding internal method", function()
                    local is_supported = supports_method(methods.lsp.SHUTDOWN)

                    assert.stub(can_run).was_not_called()
                    assert.equals(is_supported, true)
                end)

                describe("0.8", function()
                    before_each(function()
                        has.returns(true)
                    end)
                    it("should return false if server_capabilities disables method", function()
                        mock_client.server_capabilities.codeActionProvider = false
                        on_init(mock_client)

                        local is_supported = mock_client.supports_method(methods.lsp.CODE_ACTION)

                        assert.stub(can_run).was_not_called()
                        assert.equals(is_supported, false)
                    end)
                end)

                describe("0.7", function()
                    before_each(function()
                        has.returns(false)
                    end)
                    it("should return false if resolved_capabilities disables method", function()
                        mock_client.resolved_capabilities.code_action = false
                        on_init(mock_client)

                        local is_supported = mock_client.supports_method(methods.lsp.CODE_ACTION)

                        assert.stub(can_run).was_not_called()
                        assert.equals(is_supported, false)
                    end)
                end)
            end)
        end)

        it("should clear client and id on exit", function()
            client.start_client()
            local opts = lsp.start_client.calls[1].refs[1]
            opts.on_init(mock_client)

            opts.on_exit()

            assert.falsy(client.get_client())
            assert.falsy(client.get_id())
        end)
    end)

    describe("try_add", function()
        local api
        local mock_bufname = "buffer"
        local mock_sources = { "source1", "source2" }

        -- set up attach conditions
        before_each(function()
            api = mock(vim.api, true)
            api.nvim_buf_get_option.returns("")
            api.nvim_buf_get_name.returns(mock_bufname)
            sources.get_all.returns(mock_sources)
            sources.is_available.returns(true)

            lsp.buf_attach_client.returns(true)
            lsp.buf_is_attached.returns(nil)
        end)
        after_each(function()
            api.nvim_buf_get_option:clear()
            api.nvim_buf_get_name:clear()
            mock.revert(api)
        end)

        it("should run checks and attach if conditions match", function()
            local should_attach = stub.new(nil, nil, true)
            c._set({ should_attach = should_attach })

            local did_attach = client.try_add(mock_bufnr)

            assert.stub(should_attach).was_called_with(mock_bufnr)
            assert.stub(api.nvim_buf_get_option).was_called_with(mock_bufnr, "buftype")
            assert.stub(api.nvim_buf_get_option).was_called_with(mock_bufnr, "filetype")
            assert.stub(api.nvim_buf_get_name).was_called_with(mock_bufnr)
            assert.stub(sources.get_all).was_called()
            assert.stub(sources.is_available).was_called_with(mock_sources[1], "")
            assert.stub(lsp.buf_is_attached).was_called_with(mock_bufnr, mock_client_id)
            assert.stub(lsp.buf_attach_client).was_called_with(mock_bufnr, mock_client_id)
            assert.truthy(did_attach)
        end)

        it("should not attach if user-defined should_attach returns false", function()
            local should_attach = stub.new(nil, nil, false)
            c._set({ should_attach = should_attach })

            local did_attach = client.try_add(mock_bufnr)

            assert.stub(should_attach).was_called_with(mock_bufnr)
            assert.falsy(did_attach)
        end)

        it("should not attach if buftype is not empty", function()
            api.nvim_buf_get_option.returns("nofile")

            local did_attach = client.try_add(mock_bufnr)

            assert.falsy(did_attach)
        end)

        it("should not attach if name is empty", function()
            api.nvim_buf_get_name.returns("")

            local did_attach = client.try_add(mock_bufnr)

            assert.falsy(did_attach)
        end)

        it("should not attach if no source is available", function()
            sources.is_available.returns(false)

            local did_attach = client.try_add(mock_bufnr)

            assert.falsy(did_attach)
        end)

        it("should return true but not attach again if already attached", function()
            lsp.buf_is_attached.returns(true)

            local did_attach = client.try_add(mock_bufnr)

            assert.truthy(did_attach)
            assert.stub(lsp.buf_attach_client).was_not_called()
        end)
    end)

    describe("setup_buffer", function()
        local on_attach = stub.new()
        before_each(function()
            c._set({ on_attach = on_attach })
        end)

        it("should do nothing if no client", function()
            client.setup_buffer(mock_bufnr)

            assert.stub(on_attach).was_not_called()
        end)

        it("should call on_attach with client and bufnr if client", function()
            client.start_client()
            lsp.start_client.calls[1].refs[1].on_init(mock_client)

            client.setup_buffer(mock_bufnr)

            assert.stub(on_attach).was_called_with(mock_client, mock_bufnr)
        end)
    end)

    describe("notify_client", function()
        local mock_method = "mockMethod"
        local mock_params = { key = "val" }
        local notify = stub.new()

        local on_init
        before_each(function()
            client.start_client()
            on_init = lsp.start_client.calls[1].refs[1].on_init
        end)

        it("should do nothing if no client", function()
            client.notify_client(mock_method, mock_params)

            assert.stub(notify).was_not_called()
        end)

        it("should call client.notify with method and params", function()
            mock_client.notify = notify
            on_init(mock_client)

            client.notify_client(mock_method, mock_params)

            assert.stub(notify).was_called_with(mock_method, mock_params)
        end)
    end)

    describe("resolve_handler", function()
        local mock_method = "mockMethod"
        local mock_handler = "handler"
        local mock_lsp_handler = "lsp-handler"

        local on_init
        before_each(function()
            client.start_client()
            on_init = lsp.start_client.calls[1].refs[1].on_init
        end)

        it("should return client handler if defined", function()
            mock_client.handlers = { [mock_method] = mock_handler }
            lsp.handlers[mock_method] = mock_lsp_handler

            on_init(mock_client)

            assert.equals(client.resolve_handler(mock_method), mock_handler)
        end)

        it("should return lsp handler if client handler is undefined", function()
            mock_client.handlers = { [mock_method] = nil }
            lsp.handlers[mock_method] = mock_lsp_handler

            on_init(mock_client)

            assert.equals(client.resolve_handler(mock_method), mock_lsp_handler)
        end)
    end)

    describe("update_filetypes", function()
        before_each(function()
            client.start_client()
            lsp.start_client.calls[1].refs[1].on_init(mock_client)
        end)

        it("should update client filetypes", function()
            local new_filetypes = { "javascript", "typescript" }
            sources.get_filetypes.returns(new_filetypes)

            client.update_filetypes()

            assert.stub(sources.get_filetypes).was_called()
            assert.equals(client.get_client().config.filetypes, new_filetypes)
        end)
    end)
end)
