local stub = require("luassert.stub")

describe("cache", function()
    local cache = require("null-ls.helpers").cache
    after_each(function()
        cache._reset()
    end)

    describe("by_bufnr", function()
        local mock_params = { bufnr = 1 }
        local mock_val = "mock_val"
        local mock_cb = stub.new()
        before_each(function()
            mock_cb.returns(mock_val)
        end)
        after_each(function()
            mock_cb:clear()
        end)

        it("should call cb with params", function()
            local fn = cache.by_bufnr(mock_cb)

            fn(mock_params)

            assert.stub(mock_cb).was_called_with(mock_params)
        end)

        it("should return cb return value", function()
            local fn = cache.by_bufnr(mock_cb)

            local val = fn(mock_params)

            assert.equals(val, "mock_val")
        end)

        it("should return false if cb returns nil", function()
            mock_cb.returns(nil)
            local fn = cache.by_bufnr(mock_cb)

            local val = fn(mock_params)

            assert.equals(val, false)
        end)

        it("should return cached value", function()
            local fn = cache.by_bufnr(mock_cb)
            local val = fn(mock_params)

            mock_cb.returns("other_val")
            val = fn(mock_params)

            assert.equals(val, "mock_val")
        end)

        it("should only call cb once if bufnr is the same", function()
            local fn = cache.by_bufnr(mock_cb)

            fn(mock_params)
            fn(mock_params)

            assert.stub(mock_cb).was_called(1)
        end)

        it("should only call cb once if cb returns false", function()
            mock_cb.returns(false)
            local fn = cache.by_bufnr(mock_cb)

            fn(mock_params)
            fn(mock_params)

            assert.stub(mock_cb).was_called(1)
        end)

        it("should call cb twice if bufnr is different", function()
            local fn = cache.by_bufnr(mock_cb)

            fn(mock_params)
            fn({ bufnr = 2 })

            assert.stub(mock_cb).was_called(2)
        end)
    end)
end)
