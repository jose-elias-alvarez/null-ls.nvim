local stub = require("luassert.stub")

local assert_exists = function(name)
    assert.equals(vim.fn.exists(name), 1)
end

local assert_not_exists = function(name)
    assert.equals(vim.fn.exists(name), 0)
end

describe("autocommands", function()
    local autocommands = require("null-ls.autocommands")
    after_each(function()
        autocommands.reset()
    end)

    describe("setup", function()
        it("should create plugin augroup", function()
            autocommands.setup()

            assert_exists("#" .. autocommands.names.GROUP)
        end)

        it("should register try_attach() autocommand", function()
            autocommands.setup()

            assert_exists("#" .. autocommands.names.GROUP .. "#BufEnter")
            assert_exists("#" .. autocommands.names.GROUP .. "#FocusGained")
        end)

        it("should register attach_or_refresh() autocommand", function()
            autocommands.setup()

            assert_exists("#" .. autocommands.names.GROUP .. "#User")
        end)
    end)

    describe("trigger", function()
        stub(vim, "cmd")
        after_each(function()
            vim.cmd:clear()
        end)

        local mock_name = "MockName"

        it("should trigger user autocmd", function()
            autocommands.trigger(mock_name)

            assert.stub(vim.cmd).was_called_with("doautocmd User " .. mock_name)
        end)
    end)

    describe("reset", function()
        it("should delete autocommands", function()
            autocommands.setup()

            autocommands.reset()

            assert_not_exists("#" .. autocommands.names.GROUP .. "#BufEnter")
            assert_not_exists("#" .. autocommands.names.GROUP .. "#FocusGained")
            assert_not_exists("#" .. autocommands.names.GROUP .. "#User")
        end)
    end)
end)
