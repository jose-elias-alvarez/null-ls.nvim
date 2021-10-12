local stub = require("luassert.stub")

local u = require("null-ls.utils")
local generators = require("null-ls.generators")
local methods = require("null-ls.methods")
local hover = require("null-ls.hover")

describe("hover", function()
    local mock_uri = "file:///mock-file"
    local mock_params
    before_each(function()
        mock_params = {
            textDocument = { uri = mock_uri },
        }
        u.make_params.returns(mock_params)
    end)

    describe("handler", function()
        local handler = stub.new()
        stub(generators, "run_registered")
        stub(u, "make_params")

        after_each(function()
            generators.run_registered:clear()
            u.make_params:clear()
            handler:clear()
        end)

        describe("method == HOVER", function()
            local method = methods.lsp.HOVER

            it("should call make_params with original params and internal method", function()
                hover.handler(method, mock_params, handler)

                mock_params._null_ls_handled = nil
                assert.stub(u.make_params).was_called_with(mock_params, methods.internal.HOVER)
            end)

            it("should set handled flag on params", function()
                hover.handler(method, mock_params, handler)

                assert.equals(mock_params._null_ls_handled, true)
            end)

            it("should call handler with results", function()
                hover.handler(method, mock_params, handler)

                local callback = generators.run_registered.calls[1].refs[1].callback
                callback({ "mock-results" })

                assert.stub(handler).was_called_with({ contents = { { "mock-results" } } })
            end)
        end)
    end)
end)
