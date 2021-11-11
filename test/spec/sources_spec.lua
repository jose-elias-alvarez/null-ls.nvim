local methods = require("null-ls.methods")
local sources = require("null-ls.sources")

describe("sources", function()
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

        it("should return true if filetype includes _all key", function()
            mock_source.filetypes["_all"] = true

            local is_available = sources.is_available(mock_source, "tl")

            assert.truthy(is_available)
        end)

        it("should return true if method matches and no filetype is specified", function()
            local is_available = sources.is_available(mock_source, nil, methods.internal.FORMATTING)

            assert.truthy(is_available)
        end)

        it("should return true if filetype and method match", function()
            local is_available = sources.is_available(mock_source, "lua", methods.internal.FORMATTING)

            assert.truthy(is_available)
        end)
    end)

    describe("validate_and_transform", function()
        local mock_source
        before_each(function()
            mock_source = {
                generator = { fn = function() end, opts = {}, async = false },
                name = "mock generator",
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

        it("should set default generator opts", function()
            mock_source.generator.opts = nil

            local validated = sources.validate_and_transform(mock_source)

            assert.truthy(validated)
            assert.same(validated.generator.opts, {})
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
end)
