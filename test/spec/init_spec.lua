local stub = require("luassert.stub")

local config = require("null-ls.config")
local handlers = require("null-ls.handlers")

describe("init", function()
    local null_ls = require("null-ls")

    it("should expose methods and variables", function()
        assert.equals(type(null_ls.register), "function")
        assert.equals(type(null_ls.is_registered), "function")
        assert.equals(type(null_ls.generator), "function")
        assert.equals(type(null_ls.formatter), "function")
        assert.equals(type(null_ls.builtins), "table")
        assert.equals(type(null_ls.methods), "table")
    end)

    describe("setup", function()
        before_each(function()
            stub(config, "setup")
            stub(handlers, "setup")
        end)

        after_each(function()
            config.setup:revert()
            handlers.setup:revert()

            vim.g.null_ls_disable = nil
        end)

        it("should not run setup if null_ls_disable is set", function()
            vim.g.null_ls_disable = true

            null_ls.setup()

            assert.stub(config.setup).was_not_called()
            assert.stub(handlers.setup).was_not_called()
        end)

        it("should run setup", function()
            null_ls.setup()

            assert.stub(config.setup).was_called()
            assert.stub(handlers.setup).was_called()
        end)
    end)
end)
