local stub = require("luassert.stub")

describe("config", function()
    local c = require("null-ls.config")

    local mock_source
    before_each(function()
        mock_source = {
            method = "mockMethod",
            filetypes = { "txt", "markdown" },
            generator = {
                fn = function()
                    print("I am a generator")
                end,
            },
        }
    end)

    after_each(function()
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
    end)

    describe("register", function()
        it("should register single source", function()
            c.register(mock_source)

            local generators = c.get()._generators
            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 1)
            assert.equals(vim.tbl_count(c.get()._filetypes), 2)
        end)

        it("should register source filetypes under methods if name is defined", function()
            mock_source.name = "mock-source"

            c.register(mock_source)

            local methods = c.get()._methods
            assert.truthy(methods[mock_source.method])
            assert.truthy(methods[mock_source.method][mock_source.name])
            assert.equals(methods[mock_source.method][mock_source.name], mock_source.filetypes)
        end)

        it("should not register source with same name twice", function()
            mock_source.name = "mock-source"

            c.register(mock_source)
            c.register(mock_source)

            local generators = c.get()._generators
            assert.equals(vim.tbl_count(generators[mock_source.method]), 1)
        end)

        it("should register function source", function()
            c.register(function()
                return mock_source
            end)

            local generators = c.get()._generators
            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 1)
        end)

        it("should register additional generators for same method", function()
            c.register(mock_source)
            c.register(mock_source)

            local generators = c.get()._generators
            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 2)
            assert.equals(vim.tbl_count(c.get()._filetypes), 2)
        end)

        it("should register multiple sources from simple list", function()
            c.register({ mock_source, mock_source })

            local generators = c.get()._generators
            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 2)
            assert.equals(vim.tbl_count(c.get()._filetypes), 2)
        end)

        it("should register multiple sources with shared configuration", function()
            c.register({
                name = "mock-source",
                filetypes = { "txt" }, -- should take precedence over source filetypes
                sources = { mock_source, mock_source },
            })

            local generators = c.get()._generators
            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 2)
            assert.equals(vim.tbl_count(c.get()._filetypes), 1)
            assert.equals(c.get()._names["mock-source"], true)
        end)

        it("should not register mutiple sources with same name twice", function()
            local mock_sources = {
                name = "mock-source",
                filetypes = { "txt" },
                sources = { mock_source, mock_source },
            }

            c.register(mock_sources)
            c.register(mock_sources)

            local generators = c.get()._generators
            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 2)
            assert.equals(vim.tbl_count(c.get()._filetypes), 1)
        end)
    end)

    describe("is_registered", function()
        local mock_name = "mock-name"
        local mock_sources = {
            name = mock_name,
            filetypes = { "txt" },
            sources = { mock_source, mock_source },
        }

        it("should return false if name is not registered", function()
            assert.equals(c.is_registered(mock_name), false)
        end)

        it("should return true if name is registered", function()
            c.register(mock_sources)

            assert.equals(c.is_registered(mock_name), true)
        end)
    end)

    describe("register_name", function()
        local mock_name = "mock-name"

        it("should register name", function()
            c.register_name(mock_name)

            assert.equals(c.is_registered(mock_name), true)
        end)
    end)

    describe("reset_sources", function()
        it("should reset source-related values only", function()
            c.setup({ debounce = 500, sources = { mock_source } })

            c.reset_sources()

            assert.equals(vim.tbl_count(c.get()._generators), 0)
            assert.equals(vim.tbl_count(c.get()._methods), 0)
            assert.equals(vim.tbl_count(c.get()._filetypes), 0)
            assert.equals(c.get().debounce, 500)
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
            local _names = { "my-integration" }

            local ok, err = pcall(c.setup, { _names = _names })

            assert.equals(ok, false)
            assert.matches("expected nil", err)
        end)

        it("should register sources", function()
            c.setup({ sources = { mock_source } })

            local generators = c.get()._generators

            assert.equals(vim.tbl_count(generators), 1)
            assert.equals(vim.tbl_count(generators[mock_source.method]), 1)
            assert.equals(vim.tbl_count(c.get()._filetypes), 2)
        end)
    end)
end)
