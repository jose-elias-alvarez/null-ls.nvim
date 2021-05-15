local stub = require("luassert.stub")
local a = require("plenary.async_lib")

local s = require("null-ls.state")
local sources = require("null-ls.sources")
local code_actions = require("null-ls.code-actions")

describe("code_actions", function()
    stub(a, "await")

    after_each(function() a.await:clear() end)

    -- describe("handler", function()
    --     local callback = stub.new()
    --     stub(s, "push_action")
    --     stub(s, "clear_actions")
    --     stub(sources, "run_generators")

    --     local actions
    --     before_each(function()
    --         actions = {
    --             {
    --                 title = "Mock action",
    --                 action = function()
    --                     print("I am a mock action")
    --                 end
    --             }
    --         }
    --     end)

    --     after_each(function()
    --         s.push_action:clear()
    --         s.clear_actions:clear()
    --         sources.run_generators:clear()
    --         callback:clear()
    --     end)

    --     it("should call clear_actions on run", function()
    --         code_actions.handler({}, callback)

    --         assert.stub(s.clear_actions).was_called()
    --     end)

    --     it("should call run_generators and pass actions to callback", function()
    --         a.await.returns(actions)

    --         code_actions.handler({}, callback)

    --         assert.stub(sources.run_generators).was_called()
    --         assert.spy(callback).was_called_with(actions)
    --     end)

    --     describe("postprocess", function()
    --         local postprocess
    --         before_each(function()
    --             code_actions.handler({}, callback)
    --             postprocess = sources.run_generators.calls[1].refs[2]
    --         end)

    --         it("should call push_action with preprocessed action", function()
    --             local action = actions[1]

    --             postprocess(action)

    --             local preprocessed = s.push_action.calls[1].vals[1]
    --             assert.equals(preprocessed.title, "Mock action")
    --             assert.equals(preprocessed.command, nil)
    --             assert.truthy(preprocessed.action)
    --         end)

    --         it("should assign action.command and set action to nil", function()
    --             local action = actions[1]

    --             postprocess(action)

    --             assert.equals(action.command, code_actions.NULL_LS_CODE_ACTION)
    --             assert.equals(action.action, nil)
    --         end)
    --     end)

    -- end)
end)
