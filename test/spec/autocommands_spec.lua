local stub = require("luassert.stub")

local clear_augroup = function(name)
    vim.api.nvim_exec(string.format([[
    augroup %s
        autocmd!
    augroup END
    ]], name), false)
    vim.cmd("augroup! " .. name)
end

describe("autocommands", function()
    local autocommands = require("null-ls.autocommands")
    after_each(function() clear_augroup(autocommands.names.GROUP) end)

    describe("setup", function()
        it("should create plugin augroup", function()
            autocommands.setup()

            assert.equals(vim.fn.exists("#" .. autocommands.names.GROUP), 1)
        end)

        it("should register BufEnter autocommand", function()
            autocommands.setup()

            assert.equals(vim.fn.exists("#" .. autocommands.names.GROUP ..
                                            "#BufEnter"), 1)
        end)

        it("should register User autocommand", function()
            autocommands.setup()

            assert.equals(vim.fn.exists("#" .. autocommands.names.GROUP ..
                                            "#User"), 1)
        end)
    end)

    describe("trigger", function()
        stub(vim, "cmd")
        after_each(function() vim.cmd:clear() end)

        local mock_name = "MockName"

        it("should trigger user autocmd", function()
            autocommands.trigger(mock_name)

            assert.stub(vim.cmd).was_called_with("doautocmd User " .. mock_name)
        end)
    end)
end)
