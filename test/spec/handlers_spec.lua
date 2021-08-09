local stub = require("luassert.stub")

local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

local lsp = vim.lsp

describe("handlers", function()
    local handlers = require("null-ls.handlers")

    describe("setup", function()
        local has = stub(vim.fn, "has")
        after_each(function()
            has:clear()
        end)

        it("should do nothing if nvim version is >= 0.6.0", function()
            has.returns(1)

            assert.is_not.equals(lsp.handlers[methods.lsp.CODE_ACTION], handlers.code_action_handler)
        end)

        it("should replace lsp handlers with overrides if nvim version is < 0.6.0", function()
            has.returns(0)

            handlers.setup()

            assert.equals(lsp.handlers[methods.lsp.CODE_ACTION], handlers.code_action_handler)
        end)
    end)

    describe("setup_client", function()
        local mock_client
        before_each(function()
            mock_client = {}
        end)

        it("should do nothing if _null_ls_setup flag is set", function()
            mock_client._null_ls_setup = true

            handlers.setup_client(mock_client)

            assert.falsy(mock_client.supports_method)
        end)

        it("should override client.supports_method and set _null_ls_setup flag", function()
            handlers.setup_client(mock_client)

            assert.truthy(mock_client.supports_method)
            assert.truthy(mock_client._null_ls_setup)
        end)

        describe("supports_method", function()
            local can_run = stub(generators, "can_run")
            local supports_method
            before_each(function()
                handlers.setup_client(mock_client)
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
end)
