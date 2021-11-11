local stub = require("luassert.stub")

describe("config", function()
    local c = require("null-ls.config")

    local register = stub(require("null-ls.sources"), "register")
    local reset = stub(require("null-ls.sources"), "reset")

    after_each(function()
        register:clear()
        reset:clear()

        c.reset()
    end)

    describe("get", function()
        it("should get config", function()
            c.setup({ debounce = 500 })

            assert.equals(c.get().debounce, 500)
        end)
    end)

    describe("reset", function()
        it("should reset config to defaults", function()
            c.setup({ debounce = 500 })

            c.reset()

            assert.equals(c.get().debounce, 250)
        end)

        it("should call sources.reset", function()
            c.reset()

            assert.stub(reset).was_called()
        end)
    end)

    describe("setup", function()
        it("should set simple config value", function()
            local debounce = 999

            c.setup({ debounce = debounce })

            assert.equals(c.get().debounce, debounce)
        end)

        it("should only setup config once", function()
            c.setup({ debounce = 999 })

            c.setup({ debounce = 1 })

            assert.equals(c.get().debounce, 999)
        end)

        it("should throw if simple config type does not match", function()
            local debounce = "999"

            local ok, err = pcall(c.setup, { debounce = debounce })

            assert.equals(ok, false)
            assert.matches("expected number", err)
        end)

        it("should set override config value", function()
            local on_attach = stub.new()
            local _on_attach = function()
                on_attach()
            end

            c.setup({ on_attach = _on_attach })
            c.get().on_attach()

            assert.stub(on_attach).was_called()
        end)

        it("should throw if override config type does not match", function()
            local on_attach = { "my function" }

            local ok, err = pcall(c.setup, { on_attach = on_attach })

            assert.equals(ok, false)
            assert.matches("expected function, nil", err)
        end)

        it("should throw if config value is private", function()
            local ok, err = pcall(c.setup, { _setup = true })

            assert.equals(ok, false)
            assert.matches("expected nil", err)
        end)

        it("should register sources", function()
            local mock_sources = { "mock-source", "mock-source-2" }

            c.setup({ sources = mock_sources })

            assert.stub(register).was_called_with(mock_sources)
        end)
    end)
end)
