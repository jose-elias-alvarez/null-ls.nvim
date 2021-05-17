local stub = require("luassert.stub")

local s = require("null-ls.state")
local handlers = require("null-ls.handlers")

local lsp = vim.lsp

describe("client", function()
    stub(lsp, "start_client")
    stub(lsp, "buf_attach_client")

    local client = require("null-ls.client")

    local mock_client_id = 1234
    after_each(function()
        lsp.start_client:clear()
        lsp.buf_attach_client:clear()

        s.reset()
    end)

    it("should start client with config when client_id is nil", function()
        client.attach()

        assert.stub(lsp.start_client).was_called()
        local config = lsp.start_client.calls[1].refs[1]

        assert.same(config.cmd, {
            "nvim", "--headless", "-u", "NONE", "-c",
            "lua require'null-ls'.server()"
        })
        assert.equals(config.root_dir, vim.fn.getcwd())
        assert.equals(config.name, "null-ls")
        assert.same(config.flags, {debounce_text_changes = 250})
    end)

    it("should not start client when client_id is already set", function()
        s.set_client_id(mock_client_id)

        client.attach()

        assert.stub(lsp.start_client).was_not_called()
    end)

    it("should set client_id after start", function()
        lsp.start_client.returns(mock_client_id)

        client.attach()

        assert.equals(s.get().client_id, mock_client_id)
    end)

    it("should call buf_attach_client with current bufnr and client id",
       function()
        lsp.start_client.returns(mock_client_id)

        client.attach()

        assert.stub(lsp.buf_attach_client).was_called_with(
            vim.api.nvim_get_current_buf(), mock_client_id)
    end)

    describe("on_init", function()
        stub(handlers, "setup_client")

        local on_init, mock_client
        before_each(function()
            mock_client = {id = 99}

            client.attach()
            on_init = lsp.start_client.calls[1].refs[1].on_init
        end)

        after_each(function() handlers.setup_client:clear() end)

        it("should call setup_client with client", function()
            on_init(mock_client)

            assert.stub(handlers.setup_client).was_called_with(mock_client)
        end)
    end)
end)
