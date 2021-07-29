local stub = require("luassert.stub")

local methods = require("null-ls.methods")

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
end)
