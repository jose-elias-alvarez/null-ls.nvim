local mock = require("luassert.mock")

local methods = require("null-ls.methods")

local client = mock(require("null-ls.client"), true)
local diagnostics = mock(require("null-ls.diagnostics"), true)
local s = mock(require("null-ls.state"), true)

describe("sources", function()
    local sources = require("null-ls.sources")

    after_each(function()
        client.on_source_change:clear()
        client.update_filetypes:clear()
        diagnostics.hide_source_diagnostics:clear()
        s.push_conditional_source:clear()

        sources._reset()
    end)

    describe("is_available", function()
        local mock_source
        before_each(function()
            mock_source = {
                generator = {},
                filetypes = { ["lua"] = true },
                methods = { [methods.internal.FORMATTING] = true },
            }
        end)

        it("should return false if source generator failed", function()
            mock_source.generator._failed = true

            local is_available = sources.is_available(mock_source)

            assert.falsy(is_available)
        end)

        it("should return false if source is disabled", function()
            mock_source._disabled = true

            local is_available = sources.is_available(mock_source)

            assert.falsy(is_available)
        end)

        it("should return false if filetype does not match", function()
            local is_available = sources.is_available(mock_source, "tl")

            assert.falsy(is_available)
        end)

        it("should return false if method does not match", function()
            local is_available = sources.is_available(mock_source, nil, methods.internal.DIAGNOSTICS)

            assert.falsy(is_available)
        end)

        it("should return true if filetype matches and no method is specified", function()
            local is_available = sources.is_available(mock_source, "lua")

            assert.truthy(is_available)
        end)

        it("should return true if multiple filetypes are set and one matches", function()
            local is_available = sources.is_available(mock_source, "foo.lua.bar")

            assert.truthy(is_available)
        end)

        it("should return true if a dotted filetype is specified", function()
            mock_source.filetypes["jinja.html"] = true

            local is_available = sources.is_available(mock_source, "jinja.html")

            assert.truthy(is_available)
        end)

        it("should return false if multiple filetypes are set and one is disabled", function()
            mock_source.filetypes["bar"] = false

            local is_available = sources.is_available(mock_source, "foo.lua.bar")

            assert.falsy(is_available)
        end)

        it("should return true if filetype includes _all key", function()
            mock_source.filetypes["_all"] = true

            local is_available = sources.is_available(mock_source, "tl")

            assert.truthy(is_available)
        end)

        it("should return false if filetype is disabled", function()
            mock_source.filetypes["_all"] = true
            mock_source.filetypes["tl"] = false

            local is_available = sources.is_available(mock_source, "tl")

            assert.falsy(is_available)
        end)

        it("should return true if method matches and no filetype is specified", function()
            local is_available = sources.is_available(mock_source, nil, methods.internal.FORMATTING)

            assert.truthy(is_available)
        end)

        it("should return true if method has override", function()
            mock_source.methods = { [methods.internal.DIAGNOSTICS_ON_SAVE] = true }

            local is_available = sources.is_available(mock_source, nil, methods.internal.DIAGNOSTICS_ON_OPEN)

            assert.truthy(is_available)
        end)

        it("should return true if filetype and method match", function()
            local is_available = sources.is_available(mock_source, "lua", methods.internal.FORMATTING)

            assert.truthy(is_available)
        end)
    end)

    describe("get_available", function()
        local mock_sources = {
            {
                filetypes = { ["lua"] = true },
                generator = {},
                methods = { [methods.internal.FORMATTING] = true },
            },
            {
                filetypes = { ["teal"] = true },
                generator = {},
                methods = { [methods.internal.DIAGNOSTICS] = true },
            },
        }
        before_each(function()
            sources._set(mock_sources)
        end)

        it("should get available sources by filetype", function()
            local available = sources.get_available("lua")

            assert.equals(#available, 1)
        end)

        it("should get available sources by method", function()
            local available = sources.get_available(nil, methods.internal.DIAGNOSTICS)

            assert.equals(#available, 1)
        end)
    end)

    describe("get", function()
        before_each(function()
            local first_source = {
                name = "first-mock-source",
                methods = { [methods.internal.FORMATTING] = true },
                id = 1,
            }
            local second_source = {
                name = "second-mock-source",
                methods = { [methods.internal.DIAGNOSTICS] = true },
                id = 2,
            }
            local third_source = {
                name = "third-mock-source",
                methods = { [methods.internal.FORMATTING] = true },
                id = 3,
            }
            sources._set({ first_source, second_source, third_source })
        end)

        describe("string query", function()
            it("should get sources matching name query (partial match)", function()
                local matching = sources.get("mock")

                assert.truthy(#matching == 3)
            end)

            it("should get source matching name query (exact match)", function()
                local matching = sources.get("first-mock-source")

                assert.truthy(#matching == 1)
            end)

            it("should get source matching name query (partial match)", function()
                local matching = sources.get("first")

                assert.truthy(#matching == 1)
            end)

            it("should not get any sources when name query does not match", function()
                local matching = sources.get("other-source")

                assert.truthy(#matching == 0)
            end)
        end)

        describe("simple query", function()
            it("should get sources matching name query (full match)", function()
                local matching = sources.get({ name = "mock%-source" })

                assert.truthy(#matching == 3)
            end)

            it("should get sources matching name query (partial match)", function()
                local matching = sources.get({ name = "mock" })

                assert.truthy(#matching == 3)
            end)

            it("should not get any sources when name query does not match", function()
                local matching = sources.get({ name = "other%-source" })

                assert.truthy(#matching == 0)
            end)

            it("should get sources matching method query", function()
                local matching = sources.get({ method = methods.internal.FORMATTING })

                assert.truthy(#matching == 2)
            end)

            it("should get source matching id query", function()
                local matching = sources.get({ id = 1 })

                assert.truthy(#matching == 1)
            end)
        end)

        describe("complex query", function()
            it("should get all sources if query is empty", function()
                local matching = sources.get({})

                assert.truthy(#matching == 3)
            end)

            it("should get sources matching name and method query", function()
                local matching = sources.get({ name = "mock", method = methods.internal.FORMATTING })

                assert.truthy(#matching == 2)
            end)

            it("should get source matching name and id query", function()
                local matching = sources.get({ name = "mock", id = 2 })

                assert.truthy(#matching == 1)
            end)

            it("should get source matching method and id query", function()
                local matching = sources.get({ method = methods.internal.FORMATTING, id = 1 })

                assert.truthy(#matching == 1)
            end)

            it("should not get any sources when query does not match", function()
                local matching = sources.get({ method = methods.internal.FORMATTING, id = 2 })

                assert.truthy(#matching == 0)
            end)
        end)
    end)

    describe("get_all", function()
        local mock_sources = {
            { filetypes = { ["lua"] = true } },
            { filetypes = { ["teal"] = true } },
        }
        before_each(function()
            sources._set(mock_sources)
        end)

        it("should get all registered sources", function()
            local all_sources = sources.get_all()

            assert.equals(#all_sources, #mock_sources)
        end)
    end)

    describe("get_filetypes", function()
        local mock_sources = {
            { filetypes = { ["lua"] = true } },
            { filetypes = { ["lua"] = true } },
            { filetypes = { ["teal"] = true } },
            { filetypes = { ["_all"] = true } },
        }
        before_each(function()
            sources._set(mock_sources)
        end)

        it("should get list of registered source filetypes", function()
            local filetypes = sources.get_filetypes()

            assert.equals(#filetypes, 2)
            assert.truthy(vim.tbl_contains(filetypes, "lua"))
            assert.truthy(vim.tbl_contains(filetypes, "teal"))
            assert.falsy(vim.tbl_contains(filetypes, "_all"))
        end)
    end)

    describe("deregister", function()
        before_each(function()
            local first_source = {
                name = "first-mock-source",
                methods = { [methods.internal.FORMATTING] = true },
                id = 1,
            }
            local second_source = {
                name = "second-mock-source",
                methods = { [methods.internal.DIAGNOSTICS] = true },
                id = 2,
            }
            local third_source = {
                name = "third-mock-source",
                methods = { [methods.internal.FORMATTING] = true },
                id = 3,
            }
            sources._set({ first_source, second_source, third_source })
        end)

        it("should deregister all sources matching query (partial match)", function()
            sources.deregister("mock")

            assert.truthy(#sources.get_all() == 0)
        end)

        it("should deregister source matching query (exact match)", function()
            sources.deregister("first-mock-source")

            assert.truthy(#sources.get_all() == 2)
        end)

        it("should not deregister sources not matching name query", function()
            sources.deregister("other-source")

            assert.truthy(#sources.get_all() == 3)
        end)

        it("should call client.update_filetypes", function()
            sources.deregister("mock")

            assert.stub(client.update_filetypes).was_called()
        end)
    end)

    describe("enable", function()
        local mock_source
        before_each(function()
            mock_source = {
                name = "first-mock-source",
                methods = { [methods.internal.FORMATTING] = true },
                id = 1,
                generator = {},
                _disabled = true,
            }
            sources._set({ mock_source })
        end)

        it("should enable matching source", function()
            sources.enable("mock")

            assert.truthy(#sources.get_available() == 1)
        end)

        it("should call client.on_source_change", function()
            sources.enable("mock")

            assert.stub(client.on_source_change).was_called()
        end)
    end)

    describe("disable", function()
        before_each(function()
            local mock_source = {
                name = "first-mock-source",
                methods = { [methods.internal.FORMATTING] = true },
                id = 1,
                generator = {},
            }
            sources._set({ mock_source })
        end)

        it("should disable matching source", function()
            sources.disable("mock")

            assert.truthy(#sources.get_available() == 0)
            assert.stub(diagnostics.hide_source_diagnostics).was_called_with(1)
        end)
    end)

    describe("toggle", function()
        local mock_source
        before_each(function()
            mock_source = {
                name = "first-mock-source",
                methods = { [methods.internal.FORMATTING] = true },
                id = 1,
                generator = {},
            }
            sources._set({ mock_source })
        end)

        it("should toggle matching source availability", function()
            sources.toggle("mock")
            assert.truthy(#sources.get_available() == 0)
            assert.stub(diagnostics.hide_source_diagnostics).was_called_with(1)

            sources.toggle("mock")
            assert.truthy(#sources.get_available() == 1)
        end)

        it("should call client.on_source_change", function()
            sources.toggle("mock")

            assert.stub(client.on_source_change).was_called()
        end)
    end)

    describe("validate_and_transform", function()
        local mock_source
        before_each(function()
            mock_source = {
                generator = { fn = function() end, opts = {}, async = false },
                name = "mock source",
                filetypes = { "lua" },
                method = methods.internal.FORMATTING,
            }
        end)

        it("should validate and return transformed source", function()
            local validated = sources.validate_and_transform(mock_source)

            assert.truthy(validated)
            assert.equals(validated.name, mock_source.name)
            assert.equals(validated.generator.async, mock_source.generator.async)
            assert.equals(validated.generator.fn, mock_source.generator.fn)
            assert.equals(validated.generator.opts, mock_source.generator.opts)
            assert.same(validated.filetypes, { ["lua"] = true })
            assert.same(validated.methods, { [methods.internal.FORMATTING] = true })
        end)

        it("should return immediately if source is already validated", function()
            mock_source._validated = true

            local validated = sources.validate_and_transform(mock_source)

            assert.equals(mock_source, validated)
        end)

        it("should set disabled filetypes", function()
            mock_source.disabled_filetypes = { "teal" }

            local validated = sources.validate_and_transform(mock_source)

            assert.same(validated.filetypes, { ["lua"] = true, ["teal"] = false })
        end)

        it("should handle table of methods", function()
            mock_source.method = { methods.internal.FORMATTING, methods.internal.RANGE_FORMATTING }

            local validated = sources.validate_and_transform(mock_source)

            assert.truthy(validated)
            assert.same(
                validated.methods,
                { [methods.internal.FORMATTING] = true, [methods.internal.RANGE_FORMATTING] = true }
            )
        end)

        it("should set default name", function()
            mock_source.name = nil

            local validated = sources.validate_and_transform(mock_source)

            assert.truthy(validated)
            assert.equals(validated.name, "anonymous source")
        end)

        it("should set default generator opts + name", function()
            mock_source.generator.opts = nil

            local validated = sources.validate_and_transform(mock_source)

            assert.truthy(validated)
            assert.same(validated.generator.opts, { name = mock_source.name })
        end)

        it("should handle function source", function()
            local validated = sources.validate_and_transform(function()
                return mock_source
            end)

            assert.truthy(validated)
        end)

        it("should return nil when function source returns nil", function()
            local validated = sources.validate_and_transform(function()
                return nil
            end)

            assert.falsy(validated)
        end)

        it("should throw if generator is invalid", function()
            mock_source.generator = nil

            assert.has_error(function()
                sources.validate_and_transform(mock_source)
            end)
        end)

        it("should throw if filetypes is invalid", function()
            mock_source.filetypes = nil

            assert.has_error(function()
                sources.validate_and_transform(mock_source)
            end)
        end)

        it("should throw if no method", function()
            mock_source.method = nil

            assert.has_error(function()
                sources.validate_and_transform(mock_source)
            end)
        end)

        it("should throw if method is empty", function()
            mock_source.method = {}

            assert.has_error(function()
                sources.validate_and_transform(mock_source)
            end)
        end)

        it("should throw if method does not exist", function()
            mock_source.method = "notAMethod"

            assert.has_error(function()
                sources.validate_and_transform(mock_source)
            end)
        end)

        it("should throw if generator.fn is invalid", function()
            mock_source.generator.fn = nil

            assert.has_error(function()
                sources.validate_and_transform(mock_source)
            end)
        end)

        it("should throw if generator.async is invalid", function()
            mock_source.generator.async = "true"

            assert.has_error(function()
                sources.validate_and_transform(mock_source)
            end)
        end)
    end)

    describe("register", function()
        local mock_raw_source
        before_each(function()
            mock_raw_source = {
                name = "mock source",
                method = methods.internal.CODE_ACTION,
                filetypes = { "text", "markdown" },
                generator = {
                    fn = function()
                        print("I am a generator")
                    end,
                },
            }
        end)

        local find_source = function(name)
            for _, source in ipairs(sources.get_all()) do
                if source.name == name then
                    return source
                end
            end
        end

        it("should register single source", function()
            sources.register(mock_raw_source)

            local registered = sources.get_all()
            assert.equals(vim.tbl_count(registered), 1)

            local found = find_source(mock_raw_source.name)
            assert.truthy(found)
            assert.equals(found.id, 1)
            assert.equals(found.generator.source_id, 1)

            assert.truthy(sources.is_registered(mock_raw_source.name))
        end)

        it("should increment id", function()
            for _ = 1, 20 do
                sources.register(mock_raw_source)
            end

            local registered = sources.get_all()
            for i = 1, 20 do
                assert.equals(registered[i].id, i)
            end
        end)

        it("should call client methods", function()
            sources.register(mock_raw_source)

            assert.stub(client.on_source_change).was_called()
            assert.stub(client.update_filetypes).was_called()
        end)

        it("should handle large number of duplicates", function()
            for _ = 1, 99 do
                sources.register(mock_raw_source)
            end

            local registered = sources.get_all()
            assert.equals(vim.tbl_count(registered), 99)
        end)

        it("should register multiple sources from simple list", function()
            sources.register({ mock_raw_source, mock_raw_source })

            local registered = sources.get_all()
            assert.equals(vim.tbl_count(registered), 2)
        end)

        it("should register multiple sources with shared configuration", function()
            sources.register({
                name = "shared config source",
                filetypes = { "text" }, -- should take precedence over source filetypes
                sources = { mock_raw_source, mock_raw_source },
            })

            local registered = sources.get_all()
            assert.equals(vim.tbl_count(registered), 2)
            local found = find_source("shared config source")
            assert.truthy(found)
            assert.same(found.filetypes, { ["text"] = true })
        end)

        it("should keep source config if not specified in shared config", function()
            sources.register({
                sources = { mock_raw_source, mock_raw_source },
            })

            local registered = sources.get_all()
            assert.equals(vim.tbl_count(registered), 2)
            local found = find_source("mock source")
            assert.truthy(found)
            assert.same(found.filetypes, { ["text"] = true, ["markdown"] = true })
        end)

        describe("condition", function()
            local mock_source
            before_each(function()
                mock_source = {
                    generator = { fn = function() end, opts = {}, async = false },
                    name = "mock source",
                    filetypes = { "lua" },
                    method = methods.internal.FORMATTING,
                }
            end)

            it("should push source to state instead of registering", function()
                mock_source.condition = function() end

                sources.register(mock_source)

                assert.stub(s.push_conditional_source).was_called()
                assert.equals(#sources.get({}), 0)
            end)

            it("should remove source condition and add try_register", function()
                mock_source.condition = function() end
                sources.register(mock_source)

                local transformed = s.push_conditional_source.calls[1].refs[1]

                assert.truthy(type(transformed.try_register) == "function")
                assert.truthy(type(transformed.condition) == "nil")
            end)

            it("should clear try_register on call", function()
                mock_source.condition = function() end
                sources.register(mock_source)

                local transformed = s.push_conditional_source.calls[1].refs[1]
                transformed.try_register()

                assert.truthy(type(transformed.try_register) == "nil")
            end)

            it("should register source on try_register if condition passes", function()
                mock_source.condition = function()
                    return true
                end
                sources.register(mock_source)

                local transformed = s.push_conditional_source.calls[1].refs[1]
                transformed.try_register()

                assert.equals(#sources.get({}), 1)
            end)

            it("should not register source on try_register if condition fails", function()
                mock_source.condition = function()
                    return false
                end
                sources.register(mock_source)

                local transformed = s.push_conditional_source.calls[1].refs[1]
                assert.truthy(type(transformed.try_register) == "function")
                transformed.try_register()

                assert.equals(#sources.get({}), 0)
            end)
        end)

        describe("is_registered", function()
            local mock_name = "mock-name"
            local mock_sources = {
                name = mock_name,
                filetypes = { "text" },
                sources = { mock_raw_source, mock_raw_source },
            }

            it("should return false if source and name are not registered", function()
                assert.equals(sources.is_registered(mock_name), false)
            end)

            it("should return true if source is registered", function()
                sources.register(mock_sources)

                assert.equals(sources.is_registered(mock_name), true)
            end)

            it("should return true if name is registered", function()
                sources.register_name(mock_name)

                assert.equals(sources.is_registered(mock_name), true)
            end)
        end)

        describe("register_name", function()
            local mock_name = "mock-name"

            it("should register name", function()
                sources.register_name(mock_name)

                assert.equals(sources.is_registered(mock_name), true)
            end)
        end)
    end)
end)
