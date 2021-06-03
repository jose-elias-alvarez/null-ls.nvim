local stub = require("luassert.stub")

local config = require("null-ls.config")
local autocommands = require("null-ls.autocommands")
local handlers = require("null-ls.handlers")
local s = require("null-ls.state")

describe("init", function()
    local null_ls = require("null-ls")

    it("should expose methods and variables", function()
        assert.equals(type(null_ls.register), "function")
        assert.equals(type(null_ls.is_registered), "function")
        assert.equals(type(null_ls.generator), "function")
        assert.equals(type(null_ls.formatter), "function")
        assert.equals(type(null_ls.start_server), "function")
        assert.equals(type(null_ls.try_attach), "function")
        assert.equals(type(null_ls.attach_or_refresh), "function")
        assert.equals(type(null_ls.shutdown), "function")

        assert.equals(type(null_ls.builtins), "table")
        assert.equals(type(null_ls.methods), "table")
    end)

    describe("setup", function()
        before_each(function()
            stub(config, "setup")
            stub(autocommands, "setup")
            stub(handlers, "setup")
        end)

        after_each(function()
            config.setup:revert()
            autocommands.setup:revert()
            handlers.setup:revert()

            vim.g.null_ls_disable = nil
        end)

        it("should not run setup if null_ls_disable is set", function()
            vim.g.null_ls_disable = true

            null_ls.setup()

            assert.stub(config.setup).was_not_called()
            assert.stub(autocommands.setup).was_not_called()
            assert.stub(handlers.setup).was_not_called()
        end)

        it("should run setup", function()
            null_ls.setup()

            assert.stub(config.setup).was_called()
            assert.stub(autocommands.setup).was_called()
            assert.stub(handlers.setup).was_called()
        end)
    end)

    describe("shutdown", function()
        before_each(function()
            stub(config, "reset")
            stub(autocommands, "reset")
            stub(handlers, "reset")
            stub(s, "shutdown_client")
        end)

        after_each(function()
            config.reset:revert()
            autocommands.reset:revert()
            handlers.reset:revert()
            s.shutdown_client:revert()
        end)

        it("should run reset commands and shut down client", function()
            null_ls.shutdown()

            assert.stub(handlers.reset).was_called()
            assert.stub(config.reset).was_called()
            assert.stub(autocommands.reset).was_called()
            assert.stub(s.shutdown_client).was_called()
        end)
    end)

    describe("disable", function()
        before_each(function()
            stub(config, "reset")
            stub(autocommands, "reset")
            stub(handlers, "reset")
            stub(s, "shutdown_client")
        end)

        after_each(function()
            config.reset:revert()
            autocommands.reset:revert()
            handlers.reset:revert()
            s.shutdown_client:revert()

            vim.g.null_ls_disable = nil
        end)

        it("should run shutdown method and set null_ls_disable", function()
            null_ls.disable()

            assert.stub(handlers.reset).was_called()
            assert.stub(config.reset).was_called()
            assert.stub(autocommands.reset).was_called()
            assert.stub(s.shutdown_client).was_called()

            assert.equals(vim.g.null_ls_disable, true)
        end)
    end)
end)
