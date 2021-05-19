local stub = require("luassert.stub")

local c = require("null-ls.config")
local s = require("null-ls.state")
local handlers = require("null-ls.handlers")

local lsp = vim.lsp

describe("client", function()
    stub(vim.fn, "buflisted")
    stub(vim, "tbl_contains")
    stub(lsp, "start_client")
    stub(lsp, "buf_attach_client")
    stub(handlers, "setup_client")
    stub(s, "attach")

    local client = require("null-ls.client")

    local mock_client_id = 1234
    before_each(function()
        vim.fn.buflisted.returns(1)
        vim.tbl_contains.returns(true)
        lsp.start_client.returns(mock_client_id)
    end)

    after_each(function()
        vim.fn.buflisted:clear()
        lsp.start_client:clear()
        lsp.buf_attach_client:clear()
        s.attach:clear()
        handlers.setup_client:clear()

        c.reset()
        s.reset()
    end)

    describe("try_attach", function()
        it("should return when buffer is not listed", function()
            vim.fn.buflisted.returns(0)

            client.try_attach()

            assert.stub(lsp.start_client).was_not_called()
        end)

        it("should return when config does not contain current filetype",
           function()
            vim.tbl_contains.returns(false)

            client.try_attach()

            assert.stub(lsp.start_client).was_not_called()
        end)

        it("should start client with config when client_id is nil", function()
            client.try_attach()

            assert.stub(lsp.start_client).was_called()
            local config = lsp.start_client.calls[1].refs[1]

            assert.same(config.cmd, {
                "nvim", "--headless", "-u", "NONE", "-c",
                "lua require'null-ls'.start_server()"
            })
            assert.equals(config.root_dir, vim.fn.getcwd())
            assert.equals(config.name, "null-ls")
            assert.same(config.flags, {debounce_text_changes = c.get().debounce})
        end)

        it("should not start client when client_id is already set", function()
            s.set({client_id = mock_client_id})

            client.try_attach()

            assert.stub(lsp.start_client).was_not_called()
        end)

        it("should set client_id after start", function()
            client.try_attach()

            assert.equals(s.get().client_id, mock_client_id)
        end)

        it("should attach current buffer by bufnr", function()
            client.try_attach()

            assert.stub(s.attach)
                .was_called_with(vim.api.nvim_get_current_buf())
        end)
    end)

    describe("callbacks", function()
        local mock_client
        before_each(function() mock_client = {id = 99} end)

        describe("on_init", function()
            local on_init
            before_each(function()
                client.try_attach()
                on_init = lsp.start_client.calls[1].refs[1].on_init
            end)

            it("should call setup_client with client", function()
                on_init(mock_client)

                assert.stub(handlers.setup_client).was_called_with(mock_client)
            end)

            it("should set initialized to true", function()
                on_init(mock_client)

                assert.equals(s.get().initialized, true)
            end)
        end)

        describe("on_exit", function()
            local on_exit
            before_each(function()
                client.try_attach()
                on_exit = lsp.start_client.calls[1].refs[1].on_exit
            end)

            it("should set initialized to false", function()
                on_exit(mock_client)

                assert.equals(s.get().initialized, false)
            end)
        end)

        describe("on_attach", function()
            local on_attach, mock_on_attach
            before_each(function()
                mock_on_attach = stub.new()
                local _on_attach = function() mock_on_attach() end
                c.setup({on_attach = _on_attach})

                client.try_attach()
                on_attach = lsp.start_client.calls[1].refs[1].on_attach
            end)

            it("should equal config on_attach function", function()
                on_attach()

                assert.stub(mock_on_attach).was_called()
            end)
        end)
    end)

end)
