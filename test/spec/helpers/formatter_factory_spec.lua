local stub = require("luassert.stub")
local helpers = require("null-ls.helpers")

describe("formatter_factory", function()
    local opts
    before_each(function()
        stub(helpers, "generator_factory")
        opts = { key = "val" }
    end)

    after_each(function()
        helpers.generator_factory:clear()
        helpers.generator_factory:revert()
    end)

    it("should call generator_factory with default opts", function()
        helpers.formatter_factory(opts)

        assert.stub(helpers.generator_factory).was_called_with(opts)
        assert.equals(helpers.generator_factory.calls[1].refs[1].ignore_stderr, true)
        assert.truthy(helpers.generator_factory.calls[1].refs[1].on_output)
    end)

    it("should not set ignore_stderr when explicitly set to false", function()
        opts.ignore_stderr = false

        helpers.formatter_factory(opts)

        assert.equals(helpers.generator_factory.calls[1].refs[1].ignore_stderr, false)
    end)

    it("should set from_temp_file if to_temp_file = true", function()
        opts.to_temp_file = true

        helpers.formatter_factory(opts)

        assert.equals(helpers.generator_factory.calls[1].refs[1].from_temp_file, true)
    end)

    describe("on_output", function()
        local formatter_done = stub.new()
        after_each(function()
            formatter_done:clear()
        end)

        it("should call done and return if no output", function()
            helpers.formatter_factory(opts)
            local on_formatter_output = helpers.generator_factory.calls[1].refs[1].on_output

            on_formatter_output({}, formatter_done)

            assert.stub(formatter_done).was_called()
        end)

        it("should call done with edit object", function()
            helpers.formatter_factory(opts)
            local on_formatter_output = helpers.generator_factory.calls[1].refs[1].on_output

            on_formatter_output({
                output = "new text",
                content = { "line1", "line" },
            }, formatter_done)

            assert.stub(formatter_done).was_called_with({
                { text = "new text" },
            })
        end)
    end)
end)
