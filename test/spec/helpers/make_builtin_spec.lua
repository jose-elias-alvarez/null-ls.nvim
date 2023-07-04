local stub = require("luassert.stub")
local helpers = require("null-ls.helpers")

describe("make_builtin", function()
    local opts = {
        method = "mockMethod",
        name = "mock-builtin",
        filetypes = { "lua" },
        factory = stub.new(),
        generator_opts = {
            key = "val",
            other_key = "other_val",
            nested = { nested_key = "nested_val", other_nested = "original_val" },
            args = { "first", "second" },
        },
    }
    local mock_generator = {
        fn = function()
            print("I am a generator")
        end,
    }

    local builtin
    before_each(function()
        opts.factory.returns(mock_generator)
        builtin = helpers.make_builtin(opts)
    end)

    after_each(function()
        opts.factory:clear()
    end)

    it("should return builtin with assigned opts", function()
        assert.equals(builtin.method, opts.method)
        assert.equals(builtin.filetypes, opts.filetypes)
        assert.same(builtin._opts, opts.generator_opts)
    end)

    describe("with", function()
        it("should create copy", function()
            local copy = builtin.with({ filetypes = { "text" } })

            assert.is_not.same(builtin, copy)
        end)

        it("should override filetypes", function()
            local copy = builtin.with({ filetypes = { "text" } })

            assert.same(copy.filetypes, { "text" })
        end)

        it("should override method", function()
            local copy = builtin.with({ method = "newMethod" })

            assert.equals(copy.method, "newMethod")
        end)

        it("should set disabled filetypes", function()
            local copy = builtin.with({ disabled_filetypes = { "teal" } })

            assert.same(copy.disabled_filetypes, { "teal" })
        end)

        it("should add extra filetypes", function()
            local copy = builtin.with({ extra_filetypes = { "teal" } })

            assert.same(copy.filetypes, { "lua", "teal" })
        end)

        it("should override values on opts", function()
            local copy = builtin.with({ timeout = 5000 })

            assert.equals(copy._opts.timeout, 5000)
        end)

        it("should extend args with extra_args table", function()
            local copy = builtin.with({ extra_args = { "user_first", "user_second" } })

            assert.equals(type(copy._opts.args), "function")
            assert.same(copy._opts.args(), { "first", "second", "user_first", "user_second" })
            -- Multiple calls should yield the same results
            assert.same(copy._opts.args(), { "first", "second", "user_first", "user_second" })
        end)

        it("should extend args with extra_args function", function()
            local copy = builtin.with({
                extra_args = function()
                    return { "user_first", "user_second" }
                end,
            })

            assert.equals(type(copy._opts.args), "function")
            assert.same(copy._opts.args(), { "first", "second", "user_first", "user_second" })
            assert.same(copy._opts.args(), { "first", "second", "user_first", "user_second" })
        end)

        it("should prepend args with extra_args table and prepend_extra_args user input", function()
            local copy = builtin.with({ extra_args = { "user_first", "user_second" }, prepend_extra_args = true })

            assert.equals(type(copy._opts.args), "function")
            assert.same(copy._opts.args(), { "user_first", "user_second", "first", "second" })
            -- Multiple calls should yield the same results
            assert.same(copy._opts.args(), { "user_first", "user_second", "first", "second" })
        end)

        it("should prepend args with extra_args table", function()
            local test_opts = {
                method = "mockMethod",
                name = "mock-builtin",
                filetypes = { "lua" },
                generator_opts = {
                    args = { "first", "second" },
                    prepend_extra_args = true,
                },
            }
            builtin = helpers.make_builtin(test_opts)
            local copy = builtin.with({ extra_args = { "user_first", "user_second" } })

            assert.equals(type(copy._opts.args), "function")
            assert.same(copy._opts.args(), { "user_first", "user_second", "first", "second" })
            -- Multiple calls should yield the same results
            assert.same(copy._opts.args(), { "user_first", "user_second", "first", "second" })
        end)

        it("should prepend args with extra_args function", function()
            local test_opts = {
                method = "mockMethod",
                name = "mock-builtin",
                filetypes = { "lua" },
                generator_opts = {
                    args = { "first", "second" },
                    prepend_extra_args = true,
                },
            }
            builtin = helpers.make_builtin(test_opts)
            local copy = builtin.with({
                extra_args = function()
                    return { "user_first", "user_second" }
                end,
            })

            assert.equals(type(copy._opts.args), "function")
            assert.same(copy._opts.args(), { "user_first", "user_second", "first", "second" })
            -- Multiple calls should yield the same results
            assert.same(copy._opts.args(), { "user_first", "user_second", "first", "second" })
        end)

        it("should keep original args if extra_args returns nil", function()
            local copy = builtin.with({
                extra_args = function()
                    return nil
                end,
            })

            assert.equals(type(copy._opts.args), "function")
            assert.same(copy._opts.args(), { "first", "second" })
            assert.same(copy._opts.args(), { "first", "second" })
        end)

        it("should set args to extra_args if args is nil", function()
            local test_opts = {
                method = "mockMethod",
                name = "mock-builtin",
                filetypes = { "lua" },
                generator_opts = {
                    args = nil,
                },
            }
            builtin = helpers.make_builtin(test_opts)
            local copy = builtin.with({ extra_args = { "user_first", "user_second" } })

            assert.equals(type(copy._opts.args), "function")
            assert.same(copy._opts.args(), { "user_first", "user_second" })
        end)

        it("should set args to extra_args if args returns nil", function()
            local test_opts = {
                method = "mockMethod",
                name = "mock-builtin",
                filetypes = { "lua" },
                generator_opts = {
                    args = function()
                        return nil
                    end,
                },
            }
            builtin = helpers.make_builtin(test_opts)
            local copy = builtin.with({ extra_args = { "user_first", "user_second" } })

            assert.equals(type(copy._opts.args), "function")
            assert.same(copy._opts.args(), { "user_first", "user_second" })
        end)

        it("should extend args with extra_args, but keep '-' arg last", function()
            -- local test_opts = vim.deep_copy(opts) stack overflows
            local test_opts = {
                method = "mockMethod",
                name = "mock-builtin",
                filetypes = { "lua" },
                generator_opts = {
                    args = { "first", "second", "-" },
                },
            }
            builtin = helpers.make_builtin(test_opts)
            local copy = builtin.with({ extra_args = { "user_first", "user_second" } })

            assert.equals(type(copy._opts.args), "function")
            assert.same(copy._opts.args(), { "first", "second", "user_first", "user_second", "-" })
            -- Multiple calls should yield the same results
            assert.same(copy._opts.args(), { "first", "second", "user_first", "user_second", "-" })
        end)

        it("should prepend args with extra_args, but keep '-' arg last", function()
            -- local test_opts = vim.deep_copy(opts) stack overflows
            local test_opts = {
                method = "mockMethod",
                name = "mock-builtin",
                filetypes = { "lua" },
                generator_opts = {
                    args = { "first", "second", "-" },
                    prepend_extra_args = true,
                },
            }

            builtin = helpers.make_builtin(test_opts)
            local copy = builtin.with({ extra_args = { "user_first", "user_second" } })

            assert.equals(type(copy._opts.args), "function")
            assert.same(copy._opts.args(), { "user_first", "user_second", "first", "second", "-" })
            -- Multiple calls should yield the same results
            assert.same(copy._opts.args(), { "user_first", "user_second", "first", "second", "-" })
        end)
    end)

    describe("index metatable", function()
        it("should call factory function with opts and return", function()
            local generator = builtin.generator

            assert.stub(opts.factory).was_called_with(builtin._opts)
            assert.equals(generator, mock_generator)
        end)

        it("should call factory function with override opts", function()
            local result = builtin.with({ timeout = 5000 })

            local _ = result.generator

            assert.equals(opts.factory.calls[1].refs[1].timeout, 5000)
        end)

        it("should use default factory function to assign opts to generator", function()
            local default_opts = {
                generator = {},
                generator_opts = {
                    cwd = "mock-cwd",
                    to_temp_file = false,
                },
            }
            builtin = helpers.make_builtin(default_opts)

            local generator = builtin.generator

            assert.same(generator, { opts = default_opts.generator_opts })
        end)
    end)
end)
