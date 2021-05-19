local stub = require("luassert.stub")

local autocommands = require("null-ls.autocommands")

describe("config", function()
    local c = require("null-ls.config")

    local mock_source = {
        method = "mockMethod",
        filetypes = {"txt", "markdown"},
        generators = {
            {fn = function() print("I am a generator") end},
            {fn = function() print("I am a generator") end}
        }
    }

    after_each(function() c.reset() end)

    describe("get", function()
        it("should get config", function()
            c.setup({debounce = 500})

            assert.equals(c.get().debounce, 500)
        end)
    end)

    describe("reset", function()
        it("should reset config to defaults", function()
            c.setup({debounce = 500})

            c.reset()

            assert.equals(c.get().debounce, 250)
        end)
    end)

    describe("register_source", function()
        stub(autocommands, "trigger")
        after_each(function() autocommands.trigger:clear() end)

        it("should register source generators and filetypes", function()
            c.register_source(mock_source)

            local generators = c.get().generators

            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 2)
            assert.equals(vim.tbl_count(c.get().filetypes), 2)
        end)

        it("should register additional generators for same method", function()
            c.register_source(mock_source)
            c.register_source(mock_source)

            local generators = c.get().generators

            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 4)
            assert.equals(vim.tbl_count(c.get().filetypes), 2)
        end)

        it("should call autocommands trigger method", function()
            c.register_source(mock_source)

            assert.stub(autocommands.trigger).was_called_with(
                autocommands.names.REGISTERED)
        end)
    end)

    describe("register_sources", function()
        it("should register multiple sources", function()
            c.register_sources({mock_source, mock_source})

            local generators = c.get().generators

            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 4)
            assert.equals(vim.tbl_count(c.get().filetypes), 2)
        end)
    end)

    describe("reset_sources", function()
        it("should reset sources", function()
            c.setup({debounce = 500, sources = {mock_source}})

            c.reset_sources()

            assert.equals(vim.tbl_count(c.get().generators), 0)
            assert.equals(c.get().debounce, 500)
        end)
    end)

    describe("generators", function()
        before_each(function() c.register_sources({mock_source}) end)

        it("should get generators matching method", function()
            local generators = c.generators(mock_source.method)

            assert.equals(vim.tbl_count(generators), 2)
        end)

        it("should get all generators", function()
            local all_generators = c.generators()

            assert.equals(vim.tbl_count(all_generators), 1)
            assert.equals(vim.tbl_count(all_generators[mock_source.method]), 2)
        end)
    end)

    describe("setup", function()
        it("should set on_attach", function()
            local on_attach = stub.new()
            local _on_attach = function() on_attach() end

            c.setup({on_attach = _on_attach})
            c.get().on_attach()

            assert.stub(on_attach).was_called()
        end)

        it("should set debounce", function()
            local debounce = 999

            c.setup({debounce = debounce})

            assert.equals(c.get().debounce, debounce)
        end)

        it("should register sources", function()
            c.setup({sources = {mock_source}})

            local generators = c.get().generators

            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 2)
            assert.equals(vim.tbl_count(c.get().filetypes), 2)
        end)
    end)
end)
