local sources = require("null-ls.sources")
local builtins = require("null-ls.builtins")
local methods = require("null-ls.methods")
local diagnostics = require("null-ls.diagnostics")

local test_utils = require("test.utils")

local lsp = vim.lsp
local api = vim.api

describe("e2e", function()
    after_each(function() vim.cmd("bufdo! bwipeout!") end)

    describe("diagnostics", function()
        -- lsp client needs extra to process diagnostics
        local WAIT_TIME = 350

        before_each(function()
            sources.register({
                {
                    method = methods.DIAGNOSTICS,
                    generators = {builtins.write_good}
                }
            })
        end)
        after_each(function() sources.reset() end)

        it("should correctly attach to buffer", function()
            test_utils.edit_test_file("test-file.md")

            diagnostics.attach()

            assert.equals(diagnostics._get_attached()[test_utils.test_dir ..
                              "/files/test-file.md"], true)
        end)

        it("should get buffer diagnostics on attach", function()
            test_utils.edit_test_file("test-file.md")

            diagnostics.attach()
            vim.wait(WAIT_TIME)

            local buf_diagnostics = lsp.diagnostic.get()
            assert.equals(vim.tbl_count(buf_diagnostics), 1)

            local write_good_diagnostic = buf_diagnostics[1]
            assert.equals(write_good_diagnostic.message,
                          "\"really\" can weaken meaning")
            assert.equals(write_good_diagnostic.source, "write-good")
            assert.same(write_good_diagnostic.range, {
                start = {character = 7, line = 0},
                ["end"] = {character = 13, line = 0}
            })
        end)

        it("should update buffer diagnostics on text change", function()
            test_utils.edit_test_file("test-file.md")
            diagnostics.attach()
            vim.wait(WAIT_TIME)

            -- remove "really"
            api.nvim_buf_set_text(api.nvim_get_current_buf(), 0, 6, 0, 13, {})
            vim.wait(WAIT_TIME)

            assert.equals(vim.tbl_count(lsp.diagnostic.get()), 0)
        end)

        it("should correctly detach from buffer on close", function()
            test_utils.edit_test_file("test-file.md")
            diagnostics.attach()

            vim.cmd("bufdo! bwipeout!")

            local attached = diagnostics._get_attached()
            assert.equals(
                attached[test_utils.test_dir .. "/files/test-file.md"], nil)
            assert.equals(vim.tbl_count(attached), 0)
        end)

    end)
end)
