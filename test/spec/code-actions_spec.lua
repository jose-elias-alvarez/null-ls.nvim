local stub = require("luassert.stub")
local a = require("plenary.async_lib")

local s = require("null-ls.state")
local u = require("null-ls.utils")
local generators = require("null-ls.generators")
local methods = require("null-ls.methods")
local code_actions = require("null-ls.code-actions")

describe("code_actions", function()
    stub(a, "await")
    stub(s, "clear_actions")
    stub(s, "register_action")
    stub(s, "get")
    stub(s, "run_action")

    before_each(function() s.get.returns({client_id = 99}) end)

    after_each(function()
        a.await:clear()
        s.clear_actions:clear()
        s.register_action:clear()
        s.get:clear()
        s.run_action:clear()
    end)

    describe("handler", function()
        local handler = stub.new()
        stub(generators, "run")
        stub(u, "make_params")

        after_each(function()
            generators.run:clear()
            u.make_params:clear()
            handler:clear()
        end)

        describe("method == CODE_ACTION", function()
            local method = methods.lsp.CODE_ACTION

            it("should return immediately if null_ls_ignore flag is set",
               function()
                local params = {_null_ls_ignore = true}
                code_actions.handler(method, params, handler, 1)

                assert.stub(u.make_params).was_not_called()
                assert.equals(params._null_ls_handled, nil)
            end)

            it(
                "should call make_params with original params and internal method",
                function()
                    code_actions.handler(method, {}, handler, 1)

                    assert.stub(u.make_params).was_called_with({bufnr = 1},
                                                               methods.internal
                                                                   .CODE_ACTION)
                end)

            it("should set handled flag on params", function()
                local params = {}

                code_actions.handler(method, params, handler, 1)

                assert.equals(params._null_ls_handled, true)
            end)

            it("should call handler with arguments", function()
                a.await.returns("actions")

                code_actions.handler(method, {}, handler, 1)

                assert.stub(handler).was_called_with(nil, method, "actions", 99,
                                                     1)
            end)

            describe("get_actions", function()
                it("should clear state actions", function()
                    code_actions.handler(method, {}, handler, 1)

                    assert.stub(s.clear_actions).was_called()
                end)
            end)

            describe("postprocess", function()
                local postprocess, action
                before_each(function()
                    action = {
                        title = "Mock action",
                        action = function()
                            print("I am an action")
                        end
                    }
                    code_actions.handler(method, {}, handler, 1)
                    postprocess = generators.run.calls[1].refs[2]
                end)

                it("should register action in state", function()
                    postprocess(action)

                    assert.equals(s.register_action.calls[1].refs[1].title,
                                  "Mock action")
                end)

                it("should set action command and delete function", function()
                    assert.truthy(action.action)
                    postprocess(action)

                    assert.equals(action.command, methods.internal.CODE_ACTION)
                    assert.equals(action.action, nil)
                end)
            end)
        end)
    end)

    describe("method == EXECUTE_COMMAND", function()
        local method = methods.lsp.EXECUTE_COMMAND
        local handler = stub.new()

        it("should set handled flag on params", function()
            local params = {
                command = methods.internal.CODE_ACTION,
                title = "Mock action"
            }

            code_actions.handler(method, params, handler, 1)

            assert.equals(params._null_ls_handled, true)
        end)

        it("should run action when command matches", function()
            code_actions.handler(method, {
                command = methods.internal.CODE_ACTION,
                title = "Mock action"
            }, handler, 1)

            assert.stub(s.run_action).was_called_with("Mock action")
        end)

        it("should not run action when command does not match", function()
            local params = {command = "someOtherCommand", title = "Mock action"}
            code_actions.handler(method, params, handler, 1)

            assert.stub(s.run_action).was_not_called()
            assert.equals(params._null_ls_handled, nil)
        end)
    end)
end)
