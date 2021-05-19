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
    after_each(function() clear_augroup("NullLsAttach") end)

    describe("setup", function()
        it("should create augroup for BufEnter event", function()
            autocommands.setup()

            assert.equals(vim.fn.exists("#NullLsAttach#BufEnter"), 1)
        end)
    end)
end)
