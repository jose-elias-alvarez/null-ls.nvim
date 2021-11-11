local methods = require("null-ls.methods")
local stub = require("luassert.stub")

describe("config", function()
    local c = require("null-ls.config")
    local on_register_source = stub(require("null-ls.lspconfig"), "on_register_source")
    local on_register_sources = stub(require("null-ls.lspconfig"), "on_register_sources")

    local mock_source
    before_each(function()
        mock_source = {
            name = "mock source",
            method = methods.internal.CODE_ACTION,
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
        on_register_source:clear()
        on_register_sources:clear()
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

    describe("reset_sources", function()
        it("should reset source-related tables but leave config values", function()
            c.setup({ debounce = 500, sources = { mock_source } })

            c.reset_sources()

            assert.equals(vim.tbl_count(c.get()._sources), 0)
            assert.equals(vim.tbl_count(c.get()._names), 0)
            assert.equals(c.get().debounce, 500)
        end)

        it("should call on_register_sources", function()
            c.reset_sources()

            assert.stub(on_register_sources).was_called()
        end)
    end)

    describe("register", function()
        local find_source = function(name)
            for _, source in ipairs(c.get()._sources) do
                if source.name == name then
                    return source
                end
            end
        end

        it("should register single source", function()
            c.register(mock_source)

            local sources = c.get()._sources
            assert.equals(vim.tbl_count(sources), 1)
            assert.truthy(find_source(mock_source.name))
        end)

        it("should call on_register_source with transformed source", function()
            c.register(mock_source)

            assert.stub(on_register_source).was_called_with(
                require("null-ls.sources").validate_and_transform(mock_source)
            )
        end)

        it("should handle large number of duplicates", function()
            for _ = 1, 99 do
                c.register(mock_source)
            end

            local sources = c.get()._sources
            assert.equals(vim.tbl_count(sources), 99)
        end)

        it("should register multiple sources from simple list", function()
            c.register({ mock_source, mock_source })

            local sources = c.get()._sources
            assert.equals(vim.tbl_count(sources), 2)
        end)

        it("should call on_register_source once per source", function()
            c.register({ mock_source, mock_source })

            assert.stub(on_register_source).was_called(2)
        end)

        it("should call on_register_sources only once", function()
            c.register({ mock_source, mock_source })

            assert.stub(on_register_sources).was_called(1)
        end)

        it("should register multiple sources with shared configuration", function()
            c.register({
                name = "shared config source",
                filetypes = { "txt" }, -- should take precedence over source filetypes
                sources = { mock_source, mock_source },
            })

            local sources = c.get()._sources
            assert.equals(vim.tbl_count(sources), 2)
            local found = find_source("shared config source")
            assert.truthy(found)
            assert.same(found.filetypes, { ["txt"] = true })
        end)
    end)

    describe("is_registered", function()
        local mock_name = "mock-name"
        local mock_sources = {
            name = mock_name,
            filetypes = { "txt" },
            sources = { mock_source, mock_source },
        }

        it("should return false if source and name are not registered", function()
            assert.equals(c.is_registered(mock_name), false)
        end)

        it("should return true if source is registered", function()
            c.register(mock_sources)

            assert.equals(c.is_registered(mock_name), true)
        end)

        it("should return true if name is registered", function()
            c.register_name(mock_name)

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

        it("should register source under private key and set config.sources to nil", function()
            c.setup({ sources = { mock_source } })

            local sources = c.get()._sources

            assert.equals(vim.tbl_count(sources), 1)
            assert.falsy(c.get().sources)
        end)
    end)
end)
