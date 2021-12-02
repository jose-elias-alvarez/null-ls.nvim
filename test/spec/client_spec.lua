local stub = require("luassert.stub")
local mock = require("luassert.mock")

local c = require("null-ls.config")
local methods = require("null-ls.methods")
local sources = require("null-ls.sources")
local tu = require("test.utils")

local lsp = mock(vim.lsp, true)

describe("client", function()
    local client = require("null-ls.client")

    local mock_client_id = 1
    local mock_client
    before_each(function()
        mock_client = { id = mock_client_id }
        lsp.start_client.returns(mock_client_id)
    end)

    after_each(function()
        lsp.start_client:clear()
        lsp.buf_attach_client:clear()

        c.reset()
        sources.reset()
        client._reset()

        tu.wipeout()
    end)

    describe("start_client", function()
        it("should start client with options", function()
            client.start_client()

            local opts = lsp.start_client.calls[1].refs[1]
            assert.equals(opts.name, "null-ls")
            assert.equals(opts.root_dir, vim.loop.cwd())
            assert.equals(opts.cmd, c.get().cmd)
            assert.same(opts.flags, { debounce_text_changes = c.get().debounce })
            assert.truthy(type(opts.on_init) == "function")
            assert.truthy(type(opts.on_exit) == "function")
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
        before_each(function()
            tu.edit_test_file("test-file.lua")
        end)

        after_each(function()
            lsp.buf_attach_client:clear()
            lsp.buf_is_attached.returns(nil)
        end)

        -- note that sources.register calls try_add
        it("should attach when source matches", function()
            sources.register(require("null-ls.builtins")._test.mock_code_action)

            assert.stub(lsp.buf_attach_client).was_called_with(vim.api.nvim_get_current_buf(), mock_client_id)
        end)

        it("should not attach if already attached", function()
            lsp.buf_is_attached.returns(true)
            client.start_client()

            sources.register(require("null-ls.builtins")._test.mock_code_action)

            assert.stub(lsp.buf_attach_client).was_not_called()
        end)

        it("should not attach when source is not available", function()
            sources.register(require("null-ls.builtins")._test.mock_hover)

            assert.stub(lsp.buf_attach_client).was_not_called()
        end)

        it("should not attach when no sources", function()
            client.try_add()

            assert.stub(lsp.buf_attach_client).was_not_called()
        end)

        it("should not attach when buftype is not empty string", function()
            vim.bo.buftype = "nofile"

            sources.register(require("null-ls.builtins")._test.mock_code_action)

            assert.stub(lsp.buf_attach_client).was_not_called()
        end)

        it("should not attach when buffer has no name", function()
            tu.wipeout()
            vim.bo.filetype = "lua"

            sources.register(require("null-ls.builtins")._test.mock_code_action)

            assert.stub(lsp.buf_attach_client).was_not_called()
        end)
    end)

    describe("setup_buffer", function()
        local mock_bufnr = 555
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
end)
