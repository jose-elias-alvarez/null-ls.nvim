local mock = require("luassert.mock")
local stub = require("luassert.stub")
local spy = require("luassert.spy")

local formatting = require("null-ls.builtins").formatting
mock(require("null-ls.logger"), true)

describe("formatting", function()
    describe("black", function()
        local formatter = formatting.black
        local u = require("null-ls.utils")
        local params = { bufnr = 4, bufname = "test" }
        local root_pattern
        before_each(function()
            root_pattern = stub(u, "root_pattern")
        end)
        after_each(function()
            root_pattern:revert()
        end)

        it("should set the cwd param", function()
            assert.truthy(type(formatter._opts.cwd) == "function")
            local s = spy.new(function(loc_params)
                return loc_params
            end)
            root_pattern.returns(s)
            local cwd = formatter._opts.cwd(params)
            assert.same(params.bufname, cwd)
            assert.stub(root_pattern).was.called_with("pyproject.toml")
            assert.spy(s).was.called_with(params.bufname)
        end)
    end)
end)
