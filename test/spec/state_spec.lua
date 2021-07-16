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
        action = function()
            mock_action_stub()
        end,
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
            s.set({ mock_key = "mock_val" })

            assert.equals(s.get().mock_key, "mock_val")
        end)
    end)

    describe("reset", function()
        it("should reset state to initial state", function()
            s.set({ client_id = mock_client_id })

            s.reset()
            local state = s.get()

            assert.equals(state.client_id, nil)
            assert.same(state.actions, {})
        end)
    end)

    describe("actions", function()
        describe("register_action", function()
            it("should register action under state.actions[title]", function()
                s.register_action(mock_action)

                assert.equals(s.get().actions[mock_action.title], mock_action.action)
            end)
        end)

        describe("run_action", function()
            before_each(function()
                s.register_action(mock_action)
            end)

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

    describe("cache", function()
        stub(vim, "uri_from_bufnr")
        stub(vim.api, "nvim_buf_is_loaded")

        local mock_bufnr, mock_cmd, mock_content = 54, "ls", "test.lua"
        local mock_uri = "file:///test.lua"
        before_each(function()
            vim.api.nvim_buf_is_loaded.returns(true)
            vim.uri_from_bufnr.returns(mock_uri)
        end)
        after_each(function()
            vim.api.nvim_buf_is_loaded:clear()
            vim.uri_from_bufnr:clear()
        end)

        describe("set_cache", function()
            it("should return if bufnr is not loaded", function()
                vim.api.nvim_buf_is_loaded.returns(false)

                s.set_cache(mock_bufnr, mock_cmd, mock_content)

                assert.stub(vim.api.nvim_buf_is_loaded).was_called_with(mock_bufnr)
                assert.stub(vim.uri_from_bufnr).was_not_called()
            end)

            it("should set state.cache when cache has not been set", function()
                s.set_cache(mock_bufnr, mock_cmd, mock_content)

                assert.stub(vim.uri_from_bufnr).was_called_with(mock_bufnr)
                assert.same(s.get().cache[mock_uri], { [mock_cmd] = mock_content })
            end)

            it("should set state.cache from command minus path", function()
                s.set_cache(mock_bufnr, "/path/to/" .. mock_cmd, mock_content)

                assert.stub(vim.uri_from_bufnr).was_called_with(mock_bufnr)
                assert.same(s.get().cache[mock_uri], { [mock_cmd] = mock_content })
            end)

            it("should overwrite state.cache when already set", function()
                s.set_cache(mock_bufnr, mock_cmd, mock_content)

                s.set_cache(mock_bufnr, mock_cmd, "other-file.lua")

                assert.same(s.get().cache[mock_uri], { [mock_cmd] = "other-file.lua" })
            end)
        end)

        describe("get_cache", function()
            it("should return if bufnr is not loaded", function()
                vim.api.nvim_buf_is_loaded.returns(false)

                local cached = s.get_cache(mock_bufnr, mock_cmd)

                assert.stub(vim.api.nvim_buf_is_loaded).was_called_with(mock_bufnr)
                assert.stub(vim.uri_from_bufnr).was_not_called()
                assert.equals(cached, nil)
            end)

            it("should return nil if cache for uri is not set", function()
                local cached = s.get_cache(mock_bufnr, mock_cmd)

                assert.stub(vim.uri_from_bufnr).was_called_with(mock_bufnr)
                assert.equals(cached, nil)
            end)

            it("should return cached content", function()
                s.set_cache(mock_bufnr, mock_cmd, mock_content)

                local cached = s.get_cache(mock_bufnr, mock_cmd)

                assert.equals(cached, mock_content)
            end)

            it("should return cached content minus path", function()
                s.set_cache(mock_bufnr, "/path/to/" .. mock_cmd, mock_content)

                local cached = s.get_cache(mock_bufnr, "/path/to/" .. mock_cmd)

                assert.equals(cached, mock_content)
            end)
        end)

        describe("clear_cache", function()
            it("should do nothing if cache for uri is not set", function()
                s.clear_cache(mock_uri)

                assert.equals(s.get().cache[mock_uri], nil)
            end)

            it("should clear cache for uri", function()
                s.set_cache(mock_bufnr, mock_cmd, mock_content)

                s.clear_cache(mock_uri)

                assert.equals(s.get().cache[mock_uri], nil)
            end)
        end)
    end)
end)
