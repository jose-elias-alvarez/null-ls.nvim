local spy = require("luassert.spy")
local stub = require("luassert.stub")
local a = require("plenary.async_lib")

local sources = require("null-ls.sources")

describe("code_actions", function()
    local code_actions = require("null-ls.code-actions")

    describe("handler", function()
        local callback = spy.new(function() end)
        stub(a, "await")
        stub(sources, "run_generators")

        local original, injected
        before_each(function()
            original = {"I am an original action"}
            injected = {"I was injected"}
        end)

        after_each(function()
            a.await:clear()
            sources.run_generators:clear()
            callback:clear()
        end)

        it("should pass merged actions to callback", function()
            a.await.returns(injected)

            code_actions.handler({actions = original}, callback)

            assert.spy(callback).was_called_with(
                {"I am an original action", "I was injected"})
        end)

        it("should assign action.command in postprocess callback", function()
            code_actions.handler({actions = original}, callback)

            local postprocess = sources.run_generators.calls[1].refs[2]
            postprocess(original)

            assert.equals(original.command, code_actions.NULL_LS_CODE_ACTION)
        end)
    end)

end)
