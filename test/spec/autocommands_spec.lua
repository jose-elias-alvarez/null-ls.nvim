local stub = require("luassert.stub")

local clear_augroup = function(name)
    vim.api.nvim_exec(string.format([[
    augroup %s
        autocmd!
    augroup END
    ]], name), false)
    vim.cmd("augroup! " .. name)
end

local assert_exists = function(name)
    assert.equals(vim.fn.exists(name), 1)
end

describe("autocommands", function()
    local autocommands = require("null-ls.autocommands")
    after_each(function()
        clear_augroup(autocommands.names.GROUP)
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
end)
