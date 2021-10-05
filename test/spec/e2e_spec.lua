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
main.config()
require("lspconfig")["null-ls"].setup({
    flags = {
        debounce_text_changes = nil,
        allow_incremental_sync = true,
    },
})

local get_code_actions = function()
    local current_bufnr = api.nvim_get_current_buf()
    return lsp.buf_request_sync(
        current_bufnr,
        methods.lsp.CODE_ACTION,
        { textDocument = { uri = vim.uri_from_bufnr(current_bufnr) } }
    )
end

describe("e2e", function()
    _G._TEST = true
    after_each(function()
        vim.cmd("bufdo! bdelete!")
        c.reset()
    end)

    describe("code actions", function()
        local actions, null_ls_action
        before_each(function()
            c.register(builtins._test.toggle_line_comment)

            tu.edit_test_file("test-file.lua")
            lsp_wait()

            actions = get_code_actions()
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

        it("should only register source once", function()
            c.register(builtins._test.toggle_line_comment)

            actions = get_code_actions()

            assert.equals(vim.tbl_count(actions[1].result), 1)
        end)

        it("should apply code action", function()
            vim.lsp.buf.execute_command(null_ls_action)

            assert.equals(u.buf.content(nil, true), '--print("I am a test file!")\n')
        end)

        it("should adapt code action based on params", function()
            vim.lsp.buf.execute_command(null_ls_action)

            actions = get_code_actions()
            null_ls_action = actions[1].result[1]
            assert.equals(null_ls_action.title, "Uncomment line")

            vim.lsp.buf.execute_command(null_ls_action)
            assert.equals(u.buf.content(nil, true), 'print("I am a test file!")\n')
        end)

        it("should combine actions from multiple sources", function()
            c.register(builtins._test.mock_code_action)

            actions = get_code_actions()

            assert.equals(vim.tbl_count(actions[1].result), 2)
        end)

        it("should handle code action timeout", function()
            -- action calls a script that waits for 250 ms,
            -- but action timeout is 100 ms
            c.register(builtins._test.slow_code_action)

            actions = get_code_actions()

            assert.equals(vim.tbl_count(actions[1].result), 1)
        end)
    end)

    describe("diagnostics", function()
        if vim.fn.executable("write-good") == 0 then
            print("skipping diagnostic tests (write-good not installed)")
            return
        end

        before_each(function()
            c.register(builtins.diagnostics.write_good)

            tu.edit_test_file("test-file.md")
            lsp_wait()
        end)

        it("should get buffer diagnostics on attach", function()
            local buf_diagnostics = lsp.diagnostic.get(0)
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

            assert.equals(vim.tbl_count(lsp.diagnostic.get(0)), 0)
        end)

        describe("multiple diagnostics", function()
            if vim.fn.executable("markdownlint") == 0 then
                print("skipping multiple diagnostics tests (markdownlint not installed)")
                return
            end

            it("should show diagnostics from multiple sources", function()
                c.register(builtins.diagnostics.markdownlint)
                vim.cmd("e")
                lsp_wait()

                local diagnostics = lsp.diagnostic.get(0)
                assert.equals(vim.tbl_count(diagnostics), 2)

                local markdownlint_diagnostic, write_good_diagnostic
                for _, diagnostic in ipairs(diagnostics) do
                    if diagnostic.source == "markdownlint" then
                        markdownlint_diagnostic = diagnostic
                    end
                    if diagnostic.source == "write-good" then
                        write_good_diagnostic = diagnostic
                    end
                end
                assert.truthy(markdownlint_diagnostic)
                assert.truthy(write_good_diagnostic)
            end)
        end)

        it("should format diagnostics with source-specific diagnostics_format", function()
            c.reset_sources()
            c.register(builtins.diagnostics.write_good.with({ diagnostics_format = "#{m} (#{s})" }))
            vim.cmd("e")
            lsp_wait()

            local write_good_diagnostic = lsp.diagnostic.get(0)[1]

            assert.equals(write_good_diagnostic.message, '"really" can weaken meaning (write-good)')
        end)
    end)

    describe("formatting", function()
        if vim.fn.executable("prettier") == 0 then
            print("skipping formatting tests (prettier not installed)")
            return
        end

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

        describe("from_temp_file", function()
            local prettier = builtins.formatting.prettier
            local original_args = prettier._opts.args
            before_each(function()
                c.reset()

                prettier._opts.args = { "--write", "$FILENAME" }
                prettier._opts.to_temp_file = true
                c.register(prettier)
            end)
            after_each(function()
                prettier._opts.args = original_args
                prettier._opts.from_temp_file = nil
                prettier._opts.to_temp_file = nil
            end)

            it("should format file", function()
                lsp.buf.formatting()
                lsp_wait()

                assert.equals(u.buf.content(nil, true), formatted)
            end)
        end)
    end)

    describe("range formatting", function()
        if vim.fn.executable("prettier") == 0 then
            print("skipping range formatting tests (prettier not installed)")
            return
        end

        -- only first line should be formatted
        local formatted = 'import { User } from "./test-types";\nimport {Other} from "./test-types"\n'

        before_each(function()
            c.register(builtins.formatting.prettier)
            tu.edit_test_file("range-formatting.js")
            assert.is_not.equals(u.buf.content(nil, true), formatted)

            lsp_wait()
        end)

        it("should format specified range", function()
            vim.cmd("normal ggV")

            lsp.buf.range_formatting()
            lsp_wait()

            assert.equals(u.buf.content(nil, true), formatted)
        end)
    end)

    describe("temp file source", function()
        if vim.fn.executable("tl") == 0 then
            print("skipping temp file source tests (teal not installed)")
            return
        end

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

            local buf_diagnostics = lsp.diagnostic.get(0)
            assert.equals(vim.tbl_count(buf_diagnostics), 1)

            local tl_check_diagnostic = buf_diagnostics[1]
            assert.equals(tl_check_diagnostic.message, "in return value: got string, expected number")
            assert.equals(tl_check_diagnostic.source, "tl check")
            assert.same(tl_check_diagnostic.range, {
                start = { character = 52, line = 0 },
                ["end"] = { character = 0, line = 1 },
            })
        end)
    end)

    describe("cached generator", function()
        local actions, null_ls_action
        before_each(function()
            c.register(builtins._test.cached_code_action)
            tu.edit_test_file("test-file.txt")
            lsp_wait()

            actions = get_code_actions()
            null_ls_action = actions[1].result[1]
        end)
        after_each(function()
            actions = nil
            null_ls_action = nil
        end)

        it("should cache results after running action once", function()
            assert.equals(null_ls_action.title, "Not cached")

            actions = get_code_actions()
            null_ls_action = actions[1].result[1]

            assert.equals(null_ls_action.title, "Cached")
        end)

        it("should reset cache when file is edited", function()
            assert.equals(null_ls_action.title, "Not cached")

            api.nvim_buf_set_lines(0, 0, 1, false, { "print('new content')" })
            lsp_wait()

            actions = get_code_actions()
            null_ls_action = actions[1].result[1]
            assert.equals(null_ls_action.title, "Not cached")
        end)
    end)

    describe("sequential formatting", function()
        it("should format file sequentially", function()
            c.register(builtins._test.first_formatter)
            c.register(builtins._test.second_formatter)
            tu.edit_test_file("test-file.txt")
            lsp_wait()

            lsp.buf.formatting()
            lsp_wait()

            assert.equals(u.buf.content(nil, true), "sequential\n")
        end)

        it("should format file according to source order", function()
            c.register(builtins._test.second_formatter)
            c.register(builtins._test.first_formatter)
            tu.edit_test_file("test-file.txt")
            lsp_wait()

            lsp.buf.formatting()
            lsp_wait()

            assert.equals(u.buf.content(nil, true), "first\n")
        end)

        it("should skip formatters that fail runtime conditions", function()
            c.register(builtins._test.first_formatter)
            c.register(builtins._test.runtime_skipped_formatter)
            tu.edit_test_file("test-file.txt")
            lsp_wait()

            lsp.buf.formatting()
            lsp_wait()

            assert.equals(u.buf.content(nil, true), "first\n")
        end)
    end)
end)
