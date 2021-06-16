local builtins = require("null-ls.builtins")
local methods = require("null-ls.methods")
local main = require("null-ls")

local c = require("null-ls.config")
local u = require("null-ls.utils")
local tu = require("test.utils")

local lsp = vim.lsp
local api = vim.api

-- need to wait for most LSP commands to pass through the client
-- setting this lower reduces testing time but is more likely to cause failures
local lsp_wait = function()
    vim.wait(400)
end

main.setup()

describe("e2e", function()
    _G._TEST = true
    after_each(function()
        vim.cmd("bufdo! bdelete!")
        c.reset_sources()
    end)

    describe("code actions", function()
        local actions, null_ls_action
        before_each(function()
            c.register(builtins._test.toggle_line_comment)

            tu.edit_test_file("test-file.lua")
            lsp_wait()

            actions = lsp.buf_request_sync(api.nvim_get_current_buf(), methods.lsp.CODE_ACTION)
            null_ls_action = actions[1].result[1]
        end)

        after_each(function()
            actions = nil
            null_ls_action = nil
        end)

        it("should get code action", function()
            assert.equals(vim.tbl_count(actions[1].result), 1)

            assert.equals(null_ls_action.title, "Comment line")
            assert.equals(null_ls_action.command, methods.internal.CODE_ACTION)
        end)

        it("should apply code action", function()
            vim.lsp.buf.execute_command(null_ls_action)

            assert.equals(u.buf.content(nil, true), '--print("I am a test file!")\n')
        end)

        it("should adapt code action based on params", function()
            vim.lsp.buf.execute_command(null_ls_action)

            actions = lsp.buf_request_sync(api.nvim_get_current_buf(), methods.lsp.CODE_ACTION)
            null_ls_action = actions[1].result[1]
            assert.equals(null_ls_action.title, "Uncomment line")

            vim.lsp.buf.execute_command(null_ls_action)
            assert.equals(u.buf.content(nil, true), 'print("I am a test file!")\n')
        end)

        it("should combine actions from multiple sources", function()
            c.register(builtins._test.mock_code_action)

            actions = lsp.buf_request_sync(api.nvim_get_current_buf(), methods.lsp.CODE_ACTION)

            assert.equals(vim.tbl_count(actions[1].result), 2)
        end)

        it("should handle code action timeout", function()
            -- action calls a script that waits for 250 ms,
            -- but action timeout is 100 ms
            c.register(builtins._test.slow_code_action)

            actions = lsp.buf_request_sync(api.nvim_get_current_buf(), methods.lsp.CODE_ACTION)

            assert.equals(vim.tbl_count(actions[1].result), 1)
        end)
    end)

    describe("diagnostics", function()
        before_each(function()
            c.register(builtins.diagnostics.write_good)

            tu.edit_test_file("test-file.md")
            lsp_wait()
        end)

        it("should get buffer diagnostics on attach", function()
            local buf_diagnostics = lsp.diagnostic.get()
            assert.equals(vim.tbl_count(buf_diagnostics), 1)

            local write_good_diagnostic = buf_diagnostics[1]
            assert.equals(write_good_diagnostic.message, '"really" can weaken meaning')
            assert.equals(write_good_diagnostic.source, "write-good")
            assert.same(write_good_diagnostic.range, {
                start = { character = 7, line = 0 },
                ["end"] = { character = 13, line = 0 },
            })
        end)

        it("should update buffer diagnostics on text change", function()
            -- remove "really"
            api.nvim_buf_set_text(api.nvim_get_current_buf(), 0, 6, 0, 13, {})
            lsp_wait()

            assert.equals(vim.tbl_count(lsp.diagnostic.get()), 0)
        end)

        it("should combine diagnostics from multiple sources", function()
            vim.cmd("bufdo! bdelete!")

            c.register(builtins._test.mock_diagnostics)
            tu.edit_test_file("test-file.md")
            lsp_wait()

            assert.equals(vim.tbl_count(lsp.diagnostic.get()), 2)
        end)
    end)

    describe("formatting", function()
        local formatted = 'import { User } from "./test-types";\n'

        local bufnr
        before_each(function()
            c.register(builtins.formatting.prettier)

            tu.edit_test_file("test-file.js")
            -- make sure file wasn't accidentally saved
            assert.is_not.equals(u.buf.content(nil, true), formatted)

            bufnr = api.nvim_get_current_buf()
            lsp_wait()
        end)

        it("should format file", function()
            lsp.buf.formatting()
            lsp_wait()

            assert.equals(u.buf.content(nil, true), formatted)
        end)

        it("should keep marks", function()
            -- set mark at end of line
            vim.cmd("normal $ma")

            local start_pos
            for _, mark in pairs(vim.fn.getmarklist(bufnr)) do
                if mark.mark == "'a" then
                    start_pos = mark.pos
                end
            end
            assert.truthy(start_pos)

            lsp.buf.formatting()
            lsp_wait()

            local found = false
            for _, mark in pairs(vim.fn.getmarklist(bufnr)) do
                if mark.mark == "'a" then
                    found = true
                    assert.same(start_pos, mark.pos)
                end
            end
            assert.truthy(found)
        end)

        it("should keep cursor position in other window", function()
            local pos = { 1, 5 }
            vim.cmd("vsplit")
            local split_win = api.nvim_get_current_win()
            api.nvim_win_set_cursor(split_win, pos)
            vim.cmd("wincmd w")

            lsp.buf.formatting()
            lsp_wait()

            assert.same(api.nvim_win_get_cursor(split_win), pos)
        end)
    end)

    describe("temp file source", function()
        before_each(function()
            api.nvim_exec(
                [[
            augroup NullLsTesting
                autocmd!
                autocmd BufEnter *.tl set filetype=teal
            augroup END
            ]],
                false
            )
            c.register(builtins.diagnostics.teal)

            tu.edit_test_file("test-file.tl")
            lsp_wait()
        end)
        after_each(function()
            api.nvim_exec(
                [[
            augroup NullLsTesting
                autocmd!
            augroup END
            ]],
                false
            )
            vim.cmd("augroup! NullLsTesting")
        end)

        it("should handle source that uses temp file", function()
            -- replace - with .., which will mess up the return type
            api.nvim_buf_set_text(api.nvim_get_current_buf(), 0, 52, 0, 53, { ".." })
            lsp_wait()

            local buf_diagnostics = lsp.diagnostic.get()
            assert.equals(vim.tbl_count(buf_diagnostics), 1)

            local tl_check_diagnostic = buf_diagnostics[1]
            assert.equals(tl_check_diagnostic.message, "in return value: got string, expected number")
            assert.equals(tl_check_diagnostic.source, "tl check")
            assert.same(tl_check_diagnostic.range, {
                start = { character = 52, line = 0 },
                ["end"] = { character = 54, line = 0 },
            })
        end)
    end)

    describe("cached generator", function()
        local actions, null_ls_action
        before_each(function()
            c.register(builtins._test.cached_code_action)

            tu.edit_test_file("test-file.lua")
            lsp_wait()

            actions = lsp.buf_request_sync(api.nvim_get_current_buf(), methods.lsp.CODE_ACTION)
            null_ls_action = actions[1].result[1]
        end)

        it("should cache results after running action once", function()
            assert.equals(null_ls_action.title, "Not cached")

            actions = lsp.buf_request_sync(api.nvim_get_current_buf(), methods.lsp.CODE_ACTION)
            null_ls_action = actions[1].result[1]

            assert.equals(null_ls_action.title, "Cached")
        end)

        it("should reset cache when file is edited", function()
            assert.equals(null_ls_action.title, "Not cached")
            api.nvim_buf_set_lines(api.nvim_get_current_buf(), 0, 0, false, { "print('new content')" })
            lsp_wait()

            actions = lsp.buf_request_sync(api.nvim_get_current_buf(), methods.lsp.CODE_ACTION)
            null_ls_action = actions[1].result[1]

            assert.equals(null_ls_action.title, "Not cached")
        end)
    end)
end)

main.shutdown()
