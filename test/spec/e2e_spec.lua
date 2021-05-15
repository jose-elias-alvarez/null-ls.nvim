local s = require("null-ls.state")
local sources = require("null-ls.sources")
local builtins = require("null-ls.builtins")
local methods = require("null-ls.methods")
local main = require("null-ls")
local NULL_LS_CODE_ACTION = require("null-ls.code-actions").NULL_LS_CODE_ACTION

local tu = require("test.utils")

local lsp = vim.lsp
local api = vim.api

-- need to wait for LSP commands
-- also need to wait for client to shut down to avoid orphan processes
local wait_for_lsp_client = function() vim.wait(400) end

describe("e2e", function()
    before_each(function() main.setup() end)
    after_each(function()
        vim.cmd("bufdo! bwipeout!")
        sources.reset()
        main.reset()

        wait_for_lsp_client()
    end)

    describe("code actions", function()
        before_each(function()
            sources.register({
                {
                    method = methods.CODE_ACTION,
                    generators = {builtins.toggle_line_comment}
                }
            })
            tu.edit_test_file("test-file.lua")

            wait_for_lsp_client()
        end)

        it("should get null-ls code action", function()
            local actions = lsp.buf_request_sync(api.nvim_get_current_buf(),
                                                 methods.CODE_ACTION)

            assert.equals(vim.tbl_count(actions), 1)

            local null_ls_action = actions[1].result[1]
            assert.equals(null_ls_action.title, "Comment line")
            assert.equals(null_ls_action.command, NULL_LS_CODE_ACTION)
        end)
    end)

    describe("diagnostics", function()
        before_each(function()
            sources.register({
                {
                    method = methods.DIAGNOSTICS,
                    generators = {builtins.write_good}
                }
            })
            tu.edit_test_file("test-file.md")

            wait_for_lsp_client()
        end)

        it("should correctly attach to buffer", function()
            assert.equals(s.is_attached(tu.test_file_path("test-file.md")), true)
        end)

        it("should get buffer diagnostics on attach", function()
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
            -- remove "really"
            api.nvim_buf_set_text(api.nvim_get_current_buf(), 0, 6, 0, 13, {})
            wait_for_lsp_client()

            assert.equals(vim.tbl_count(lsp.diagnostic.get()), 0)
        end)

        it("should correctly detach from buffer on close", function()
            assert.equals(s.is_attached(tu.test_file_path("test-file.md")), true)

            vim.cmd("bufdo! bwipeout!")

            assert.equals(s.is_attached(tu.test_file_path("test-file.md")), nil)
            assert.equals(vim.tbl_count(s.get().attached), 0)
        end)
    end)
end)
