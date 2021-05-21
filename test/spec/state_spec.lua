local stub = require("luassert.stub")

local loop = require("null-ls.loop")
local methods = require("null-ls.methods")
local c = require("null-ls.config")
local s = require("null-ls.state")

describe("state", function()
    local mock_client_id = 1234
    local mock_action_stub = stub.new()
    local mock_action = {
        title = "Mock action",
        -- need to wrap to pass validation
        action = function() mock_action_stub() end
    }

    after_each(function()
        mock_action_stub:clear()
        s.reset()
    end)

    describe("get", function()
        it("should get initial state", function()
            local state = s.get()

            assert.equals(state.client_id, nil)
            assert.same(state.actions, {})
        end)

        it("should get updated state", function()
            s.set({mock_key = "mock_val"})

            assert.equals(s.get().mock_key, "mock_val")
        end)
    end)

    describe("reset", function()
        it("should reset state to initial state", function()
            s.set({client_id = mock_client_id})

            s.reset()
            local state = s.get()

            assert.equals(state.client_id, nil)
            assert.same(state.actions, {})
        end)
    end)

    describe("client", function()
        describe("notify_client", function()
            local notify = stub.new()
            local mock_params = {key = "val"}

            local mock_client
            before_each(function()
                mock_client = {notify = notify}
                s.set({client = mock_client})
            end)

            after_each(function()
                notify:clear()
                s.reset()
            end)

            it("should return immediately if client does not exist", function()
                s.reset()

                s.notify_client("mockMethod", mock_params)

                assert.stub(notify).was_not_called()
            end)

            it("should should call client.notify with method and params",
               function()
                s.notify_client("mockMethod", mock_params)

                assert.stub(notify).was_called_with("mockMethod", mock_params)
            end)
        end)

        describe("initialize", function()
            stub(loop, "timer")

            local notify = stub.new()
            local mock_client
            before_each(function() mock_client = {notify = notify} end)
            after_each(function()
                loop.timer:clear()
                s.reset()
            end)

            it("should assign client to state", function()
                s.initialize(mock_client)

                assert.equals(s.get().client, mock_client)
            end)

            it("should create timer and assign to state", function()
                loop.timer.returns("timer")

                s.initialize(mock_client)

                assert.equals(s.get().keep_alive_timer, "timer")
            end)

            describe("timer", function()
                it("should create timer with correct args", function()
                    s.initialize(mock_client)

                    assert.equals(loop.timer.calls[1].refs[1], 0)
                    assert.equals(loop.timer.calls[1].refs[2],
                                  c.get().keep_alive_interval)
                    assert.equals(loop.timer.calls[1].refs[3], true)
                    assert.truthy(loop.timer.calls[1].refs[4])
                end)

                it("should call notify_client on timer callback", function()
                    s.initialize(mock_client)

                    local callback = loop.timer.calls[1].refs[4]
                    callback()

                    assert.stub(notify).was_called_with(
                        methods.internal._NOTIFICATION,
                        {timeout = c.get().keep_alive_interval})
                end)
            end)
        end)

        describe("shutdown_client", function()
            stub(vim.lsp, "stop_client")
            stub(vim, "wait")
            local is_stopped = stub.new()
            local mock_client

            before_each(function()
                mock_client = {is_stopped = is_stopped}
                s.set({client_id = mock_client_id, client = mock_client})
            end)
            after_each(function()
                vim.lsp.stop_client:clear()
                vim.wait:clear()
                is_stopped:clear()
                s.reset()
            end)

            it("should return if state client is nil", function()
                s.reset()

                s.shutdown_client()

                assert.stub(vim.lsp.stop_client).was_not_called()
            end)

            it("should call stop_client with state client_id", function()
                s.shutdown_client()

                assert.stub(vim.lsp.stop_client).was_called_with(mock_client_id)
            end)

            it("should reset state", function()
                s.shutdown_client()

                assert.equals(s.get().client_id, nil)
            end)

            describe("wait", function()
                it("should call vim.wait with default timeout and interval",
                   function()
                    s.shutdown_client()

                    assert.equals(vim.wait.calls[1].refs[1], 5000)
                    assert.equals(vim.wait.calls[1].refs[3], 10)
                end)

                it("should call vim.wait with specified timeout", function()
                    s.shutdown_client(1000)

                    assert.equals(vim.wait.calls[1].refs[1], 1000)
                end)

                describe("callback", function()
                    it("should return true if client is nil", function()
                        s.shutdown_client()

                        local callback = vim.wait.calls[1].refs[2]

                        assert.equals(callback(), true)
                    end)

                    it(
                        "should return true if client is_stopped method returns true",
                        function()
                            is_stopped.returns(true)
                            s.shutdown_client()

                            local callback = vim.wait.calls[1].refs[2]
                            s.set({client = mock_client})

                            assert.equals(callback(), true)
                            assert.stub(is_stopped).was_called()
                        end)

                    it("should return false otherwise", function()
                        is_stopped.returns(false)
                        s.shutdown_client()

                        local callback = vim.wait.calls[1].refs[2]
                        s.set({client = mock_client})

                        assert.equals(callback(), false)
                        assert.stub(is_stopped).was_called()
                    end)
                end)
            end)
        end)

        describe("attach", function()
            stub(vim.lsp, "buf_attach_client")
            stub(vim, "uri_from_bufnr")

            local mock_bufnr, mock_uri = 75, "file:///mock-file.lua"
            before_each(function()
                s.set({client_id = mock_client_id})
                vim.uri_from_bufnr.returns(mock_uri)
            end)

            after_each(function()
                vim.lsp.buf_attach_client:clear()
                vim.uri_from_bufnr:clear()
            end)

            it("should call buf_attach_client with bufnr and client_id",
               function()
                s.attach(mock_bufnr)

                assert.stub(vim.lsp.buf_attach_client).was_called_with(
                    mock_bufnr, mock_client_id)
            end)

            it(
                "should not call buf_attach_client again if buffer is already attached",
                function()
                    s.attach(mock_bufnr)

                    s.attach(mock_bufnr)

                    assert.stub(vim.lsp.buf_attach_client).was_called(1)
                end)

            it("should save bufnr in state.attached under uri", function()
                s.attach(mock_bufnr)

                assert.equals(s.get().attached[mock_uri], mock_bufnr)
            end)
        end)
    end)

    describe("register_action", function()
        it("should register action under state.actions[title]", function()
            s.register_action(mock_action)

            assert.equals(s.get().actions[mock_action.title], mock_action.action)
        end)
    end)

    describe("run_action", function()
        before_each(function() s.register_action(mock_action) end)

        it("should run action matching title", function()
            s.run_action(mock_action.title)

            assert.stub(mock_action_stub).was_called()
        end)
    end)

    describe("clear_actions", function()
        it("should clear state actions", function()
            s.register_action(mock_action)

            s.clear_actions()

            assert.equals(s.get().actions[mock_action.title], nil)
        end)
    end)
end)
