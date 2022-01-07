local stub = require("luassert.stub")
local mock = require("luassert.mock")

local c = require("null-ls.config")
local methods = require("null-ls.methods")

local client = mock(require("null-ls.client"), true)

describe("rpc", function()
    local rpc = require("null-ls.rpc")

    after_each(function()
        c.reset()
    end)

    describe("setup", function()
        local original_rpc_start = require("vim.lsp.rpc").start
        local rpc_start, start
        before_each(function()
            rpc_start = stub(require("vim.lsp.rpc"), "start")
            start = stub(rpc, "start")
        end)
        after_each(function()
            require("vim.lsp.rpc")._null_ls_setup = nil
            require("vim.lsp.rpc").start = original_rpc_start
            start:revert()
        end)

        it("should override original rpc.start method and set setup flag", function()
            rpc.setup()

            assert.is_not.equals(require("vim.lsp.rpc").start, rpc_start)
            assert.truthy(require("vim.lsp.rpc")._null_ls_setup)
        end)

        it("should not do anything if already set up", function()
            require("vim.lsp.rpc")._null_ls_setup = true

            rpc.setup()

            assert.equals(require("vim.lsp.rpc").start, rpc_start)
        end)

        it("should call original rpc_start method if config does not exist", function()
            rpc.setup()

            require("vim.lsp.rpc").start("command", "args", "dispatchers", "other_args")

            assert.stub(rpc_start).was_called_with("command", "args", "dispatchers", "other_args")
        end)

        it("should call rpc.start override if command matches default", function()
            rpc.setup()

            require("vim.lsp.rpc").start("nvim", "args", "dispatchers", "other_args")

            assert.stub(rpc.start).was_called_with("dispatchers")
        end)

        it("should call rpc.start override if command matches custom command", function()
            c._set({ cmd = { "custom" } })
            rpc.setup()

            require("vim.lsp.rpc").start("custom", "args", "dispatchers", "other_args")

            assert.stub(rpc.start).was_called_with("dispatchers")
        end)
    end)

    describe("start", function()
        local wait_for_scheduler = function()
            vim.wait(0)
        end

        stub(require("null-ls.diagnostics"), "handler")
        stub(require("null-ls.code-actions"), "handler")
        stub(require("null-ls.formatting"), "handler")
        stub(require("null-ls.hover"), "handler")
        stub(require("null-ls.completion"), "handler")

        local rpc_object
        local dispatchers = { on_exit = stub.new() }

        before_each(function()
            rpc_object = rpc.start(dispatchers)
        end)
        after_each(function()
            dispatchers.on_exit:clear()
            require("null-ls.diagnostics").handler:clear()
            require("null-ls.code-actions").handler:clear()
            require("null-ls.formatting").handler:clear()
            require("null-ls.hover").handler:clear()
            require("null-ls.completion").handler:clear()
            client.get_id:clear()
            client.get_id.returns(nil)
        end)

        it("should return object with methods", function()
            assert.truthy(type(rpc_object.request) == "function")
            assert.truthy(type(rpc_object.notify) == "function")
            assert.truthy(type(rpc_object.handle.is_closing) == "function")
            assert.truthy(type(rpc_object.handle.kill) == "function")
            assert.truthy(type(rpc_object.pid) == "number")
        end)

        describe("stopped", function()
            it("should be false if not killed", function()
                assert.falsy(rpc_object.handle.is_closing())
            end)

            it("should be true if killed", function()
                rpc_object.handle.kill()

                assert.truthy(rpc_object.handle.is_closing())
            end)
        end)

        describe("handle", function()
            local callback, request
            before_each(function()
                callback = stub.new()
                request = rpc_object.request
            end)

            it("should return success response and message id", function()
                local success, message_id = request(methods.lsp.FORMATTING, {}, callback)

                assert.truthy(success)
                -- depends on test order
                assert.equals(message_id, 2)

                _, message_id = request(methods.lsp.FORMATTING, {}, callback)
                assert.equals(message_id, 3)
            end)

            it("should convert non-table params to table", function()
                request(methods.lsp.FORMATTING, "params", callback)

                assert.same(
                    require("null-ls.code-actions").handler.calls[1].refs[2],
                    { method = methods.lsp.FORMATTING, "params" }
                )
            end)

            it("should set params.client_id if id exists", function()
                local mock_client = { id = 99 }
                client.get_id.returns(mock_client.id)

                request(methods.lsp.FORMATTING, {}, callback)

                assert.same(
                    require("null-ls.code-actions").handler.calls[1].refs[2],
                    { method = methods.lsp.FORMATTING, client_id = mock_client.id }
                )
            end)

            it("should call callback with empty response if request is not handled", function()
                request(methods.lsp.FORMATTING, {}, callback)

                wait_for_scheduler()

                assert.stub(callback).was_called_with(nil, nil)
            end)

            it("should call request handlers", function()
                local method = methods.lsp.FORMATTING
                local assert_was_called = function(handler)
                    -- callback gets wrapped, so we can't assert against it
                    assert.equals(handler.calls[1].refs[1], method)
                    assert.same(handler.calls[1].refs[2], { method = method })
                end

                request(method, {}, callback)

                assert_was_called(require("null-ls.code-actions").handler)
                assert_was_called(require("null-ls.formatting").handler)
                assert_was_called(require("null-ls.hover").handler)
                assert_was_called(require("null-ls.completion").handler)
            end)

            it("should not call callback if request was handled", function()
                request(methods.lsp.FORMATTING, { _null_ls_handled = true }, callback)

                wait_for_scheduler()

                assert.stub(callback).was_not_called()
            end)
        end)

        describe("request", function()
            local callback, request
            before_each(function()
                callback = stub.new()
                request = rpc_object.request
            end)

            it("should call notify_callback if defined", function()
                local notify_callback = stub.new()
                request(methods.lsp.INITIALIZE, {}, callback, notify_callback)

                wait_for_scheduler()

                -- asserting against message_id is flaky
                assert.stub(notify_callback).was_called()
            end)

            it("should send capabilities on initialize request", function()
                request(methods.lsp.INITIALIZE, {}, callback)

                wait_for_scheduler()

                assert.stub(callback).was_called_with(nil, { capabilities = rpc.capabilities })
            end)

            it("should set stopped and send empty response on shutdown request", function()
                request(methods.lsp.SHUTDOWN, {}, callback)

                wait_for_scheduler()

                assert.stub(callback).was_called_with(nil, nil)
                -- works sometimes but is flaky due to the scheduler
                -- assert.truthy(rpc_object.handle.is_closing())
            end)

            it("should call dispatchers.on_exit on exit request", function()
                request(methods.lsp.EXIT, {}, callback)

                wait_for_scheduler()

                assert.stub(callback).was_not_called()
                assert.stub(dispatchers.on_exit).was_called_with(0, 0)
            end)
        end)

        describe("notify", function()
            local notify
            before_each(function()
                notify = rpc_object.notify
            end)

            it("should call diagnostics handler with params", function()
                notify(methods.lsp.DID_CHANGE, {})

                assert.stub(require("null-ls.diagnostics").handler).was_called_with({
                    method = methods.lsp.DID_CHANGE,
                })
            end)
        end)
    end)
end)
