local stub = require("luassert.stub")

local c = require("null-ls.config")
local methods = require("null-ls.methods")

local test_utils = require("null-ls.test-utils")

describe("utils", function()
    local u = require("null-ls.utils")

    after_each(function()
        c.reset()
    end)

    describe("join_at_newline", function()
        after_each(function()
            vim.bo.fileformat = "unix"
        end)

        it("should join text with unix line ending", function()
            vim.bo.fileformat = "unix"

            local joined = u.join_at_newline(0, { "line1", "line2", "line3" })

            assert.equals(joined, "line1\nline2\nline3")
        end)

        it("should join text with dos line ending", function()
            vim.bo.fileformat = "dos"

            local joined = u.join_at_newline(0, { "line1", "line2", "line3" })

            assert.equals(joined, "line1\r\nline2\r\nline3")
        end)

        it("should join text with mac line ending", function()
            vim.bo.fileformat = "mac"

            local joined = u.join_at_newline(0, { "line1", "line2", "line3" })

            assert.equals(joined, "line1\rline2\rline3")
        end)
    end)

    describe("split_at_newline", function()
        after_each(function()
            vim.bo.fileformat = "unix"
        end)

        it("should split text with unix line ending", function()
            vim.bo.fileformat = "unix"

            local split = u.split_at_newline(0, "line1\nline2\nline3")

            assert.same(split, { "line1", "line2", "line3" })
        end)

        it("should split text with dos line ending", function()
            vim.bo.fileformat = "dos"

            local split = u.split_at_newline(0, "line1\r\nline2\r\nline3")

            assert.same(split, { "line1", "line2", "line3" })
        end)

        it("should split text with mac line ending", function()
            vim.bo.fileformat = "mac"

            local split = u.split_at_newline(0, "line1\rline2\rline3")

            assert.same(split, { "line1", "line2", "line3" })
        end)
    end)

    describe("has_version", function()
        local has
        before_each(function()
            has = stub(vim.fn, "has")
        end)
        after_each(function()
            has:revert()
        end)

        it("should call has with full nvim version name", function()
            has.returns(0)

            u.has_version("0.6.0")

            assert.stub(has).was_called_with("nvim-0.6.0")
        end)

        it("should return false if has result is 0", function()
            has.returns(0)

            assert.falsy(u.has_version("0.6.0"))
        end)

        it("should return true if has result is greater than 0", function()
            has.returns(1)

            assert.truthy(u.has_version("0.6.0"))
        end)
    end)

    describe("is_executable", function()
        local executable
        before_each(function()
            executable = stub(vim.fn, "executable")
        end)
        after_each(function()
            executable:revert()
        end)

        it("should call executable with command", function()
            executable.returns(0)

            u.is_executable("mock-command")

            assert.stub(executable).was_called_with("mock-command")
        end)

        it("should return true and nil if result is > 0", function()
            executable.returns(1)

            local is_executable, err_msg = u.is_executable("mock-command")

            assert.truthy(is_executable)
            assert.falsy(err_msg)
        end)

        it("should return false and error message if result is 0", function()
            executable.returns(0)

            local is_executable, err_msg = u.is_executable("mock-command")

            assert.falsy(is_executable)
            assert.truthy(err_msg:find("is not executable"))
        end)
    end)

    describe("range", function()
        describe("to_lsp", function()
            it("should convert lua-friendly range to lsp range", function()
                local lua_range = { row = 5, col = 1, end_row = 6, end_col = 7 }

                local lsp_range = u.range.to_lsp(lua_range)

                assert.equals(lsp_range["start"].line, 4)
                assert.equals(lsp_range["start"].character, 0)
                assert.equals(lsp_range["end"].line, 5)
                assert.equals(lsp_range["end"].character, 6)
            end)

            it("should clamp invalid range values to 0", function()
                local lua_range = { row = -1, col = -4, end_row = -6, end_col = -7 }

                local lsp_range = u.range.to_lsp(lua_range)

                assert.equals(lsp_range["start"].line, 0)
                assert.equals(lsp_range["start"].character, 0)
                assert.equals(lsp_range["end"].line, 0)
                assert.equals(lsp_range["end"].character, 0)
            end)
        end)

        describe("from_lsp", function()
            it("should convert lsp range to lua range", function()
                local lsp_range = { ["start"] = { line = 4, character = 0 }, ["end"] = { line = 5, character = 6 } }

                local lua_range = u.range.from_lsp(lsp_range)

                assert.equals(lua_range.row, 5)
                assert.equals(lua_range.col, 1)
                assert.equals(lua_range.end_row, 6)
                assert.equals(lua_range.end_col, 7)
            end)

            it("should clamp invalid range values to 1", function()
                local lsp_range = { ["start"] = { line = -4, character = -1 }, ["end"] = { line = -5, character = -6 } }

                local lua_range = u.range.from_lsp(lsp_range)

                assert.equals(lua_range.row, 1)
                assert.equals(lua_range.col, 1)
                assert.equals(lua_range.end_row, 1)
                assert.equals(lua_range.end_col, 1)
            end)
        end)
    end)

    describe("make_params", function()
        local mock_method = "mockMethod"
        local mock_content = "I am some other content"
        before_each(function()
            test_utils.edit_test_file("test-file.lua")
        end)
        after_each(function()
            vim.cmd("bufdo! bwipeout!")
        end)

        it("should return params from minimal original params", function()
            local params = u.make_params({
                method = methods.lsp.CODE_ACTION,
            }, mock_method)

            assert.equals(params.bufname, test_utils.test_dir .. "/files/test-file.lua")
            assert.equals(params.lsp_method, methods.lsp.CODE_ACTION)
            assert.equals(params.bufnr, vim.api.nvim_get_current_buf())
            assert.equals(params.col, 0)
            assert.equals(params.row, 1)
            assert.equals(params.ft, "lua")
            assert.equals(params.method, mock_method)
            assert.same(params.content, { 'print("I am a test file!")', "" })
        end)

        it("should convert original range and assign to params.range", function()
            local original_params = {
                range = {
                    ["start"] = { line = 4, character = 0 },
                    ["end"] = { line = 5, character = 6 },
                },
            }

            local params = u.make_params(original_params)

            assert.truthy(params.range)
            assert.same(params.range, u.range.from_lsp(original_params.range))
        end)

        it("should set word_to_complete if method is COMPLETION", function()
            vim.cmd("normal 5l") -- move cursor to end of "print"

            local params = u.make_params({ method = methods.lsp.COMPLETION })

            assert.equals(params.word_to_complete, "print")
        end)

        describe("resolve_bufnr", function()
            it("should resolve bufnr from params", function()
                local params = u.make_params({
                    bufnr = vim.api.nvim_get_current_buf(),
                }, mock_method)

                assert.equals(params.bufnr, vim.api.nvim_get_current_buf())
            end)

            it("should resolve bufnr from uri", function()
                local params = u.make_params({
                    textDocument = { uri = vim.uri_from_bufnr(vim.api.nvim_get_current_buf()) },
                }, mock_method)

                assert.equals(params.bufnr, vim.api.nvim_get_current_buf())
            end)
        end)

        describe("resolve_content", function()
            describe("unix-style line endings", function()
                it("should resolve content from params on DID_OPEN", function()
                    local params = u.make_params({
                        method = methods.lsp.DID_OPEN,
                        textDocument = { text = mock_content },
                    }, mock_method)

                    assert.same(params.content, { mock_content })
                end)

                it("should resolve content from params on DID_CHANGE", function()
                    local params = u.make_params({
                        method = methods.lsp.DID_CHANGE,
                        contentChanges = { { text = mock_content } },
                    }, mock_method)

                    assert.same(params.content, { mock_content })
                end)

                it("should directly get content from buffer if method does not match", function()
                    local params = u.make_params({
                        method = "otherMethod",
                        contentChanges = { { text = mock_content } },
                    }, mock_method)

                    assert.same(params.content, { 'print("I am a test file!")', "" })
                end)
            end)

            describe("non-unix style line endings", function()
                it("should content from params on DID_OPEN", function()
                    vim.bo.fileformat = "dos"

                    local params = u.make_params({
                        method = methods.lsp.DID_OPEN,
                        textDocument = { text = mock_content },
                    }, mock_method)

                    assert.same(params.content, { mock_content })
                end)

                it("should get content from params on DID_CHANGE", function()
                    vim.bo.fileformat = "dos"

                    local params = u.make_params({
                        method = methods.lsp.DID_CHANGE,
                        contentChanges = { { text = mock_content } },
                    }, mock_method)

                    assert.same(params.content, { mock_content })
                end)

                it("should directly get content from buffer if method does not match", function()
                    vim.bo.fileformat = "dos"

                    local params = u.make_params({
                        method = "otherMethod",
                        contentChanges = { { text = mock_content } },
                    }, mock_method)

                    assert.same(params.content, { 'print("I am a test file!")', "" })
                end)
            end)
        end)
    end)

    describe("make_conditional_utils", function()
        local utils = u.make_conditional_utils()

        it("should return object containing utils", function()
            assert.truthy(type(utils.has_file) == "function")
            assert.truthy(type(utils.root_has_file) == "function")
            assert.truthy(type(utils.root_matches) == "function")
        end)

        describe("has_file", function()
            it("should return true if file exists in cwd", function()
                assert.truthy(utils.has_file("stylua.toml"))
            end)

            it("should return true if some file exists in cwd", function()
                assert.truthy(utils.has_file({ ".stylua.toml", "stylua.toml" }))
            end)

            it("should return false if some file not exists in cwd", function()
                assert.falsy(utils.has_file({ "bad-file", "bad-file2" }))
            end)

            it("should return false if file does not exist in cwd", function()
                assert.falsy(utils.has_file("bad-file"))
            end)
        end)

        describe("root_has_file", function()
            it("should return true if file exists at root", function()
                assert.truthy(utils.root_has_file("stylua.toml"))
            end)

            it("should return true if some file exists at root", function()
                assert.truthy(utils.root_has_file({ ".stylua.toml", "stylua.toml" }))
            end)

            it("should return false if some file not exists at root", function()
                assert.falsy(utils.root_has_file({ "bad-file", "bad-file2" }))
            end)

            it("should return false if file does not exist at root", function()
                assert.falsy(utils.root_has_file("bad-file"))
            end)
        end)

        describe("root_matches", function()
            it("should return true if root matches pattern", function()
                assert.truthy(utils.root_matches("null%-ls"))
            end)

            it("should return false if root does not match pattern", function()
                assert.falsy(utils.root_has_file("other%-plugin"))
            end)
        end)
    end)

    describe("buf", function()
        after_each(function()
            vim.cmd("bufdo! bwipeout!")
        end)

        describe("content", function()
            before_each(function()
                test_utils.edit_test_file("test-file.lua")
                vim.api.nvim_buf_set_option(vim.api.nvim_get_current_buf(), "eol", true)
            end)

            it("should get buffer content as table", function()
                local content = u.buf.content()

                assert.equals(type(content), "table")
                assert.same(content, { 'print("I am a test file!")', "" })
            end)

            it("should not add final newline to table when eol option is false", function()
                vim.api.nvim_buf_set_option(vim.api.nvim_get_current_buf(), "eol", false)
                local content = u.buf.content()

                assert.same(content, { 'print("I am a test file!")' })
            end)

            it("should get buffer content as string", function()
                local content = u.buf.content(nil, true)

                assert.equals(type(content), "string")
                assert.equals(content, 'print("I am a test file!")\n')
            end)

            it("should not add final newline to string when eol option is false", function()
                vim.api.nvim_buf_set_option(vim.api.nvim_get_current_buf(), "eol", false)
                local content = u.buf.content(nil, true)

                assert.equals(content, 'print("I am a test file!")')
            end)
        end)

        describe("for_each_bufnr", function()
            local callback = stub.new()
            it("should call callback once per loaded bufnr", function()
                u.buf.for_each_bufnr(callback)

                assert.stub(callback).was_called(1)
                assert.stub(callback).was_called_with(vim.api.nvim_get_current_buf())
            end)
        end)
    end)

    describe("table", function()
        describe("replace", function()
            it("should replace matching list element", function()
                local list = { "original element", "to be replaced", "don't replace me" }

                local replaced = u.table.replace(list, "to be replaced", "new element")

                assert.equals(replaced[1], "original element")
                assert.equals(replaced[2], "new element")
                assert.equals(replaced[3], "don't replace me")
            end)
        end)

        describe("uniq", function()
            it("should return table of unique elements", function()
                local start_table = { "hello", "hello", "goodbye" }

                local unique_table = u.table.uniq(start_table)

                assert.equals(#unique_table, 2)
            end)
        end)
    end)

    describe("handle_function_opt", function()
        local function_opt = stub.new()
        -- stubs aren't functions, so wrap
        local wrapper = function(...)
            return function_opt(...)
        end

        after_each(function()
            function_opt:clear()
            function_opt.returns(nil)
        end)

        it("should pass args to function opt", function()
            u.handle_function_opt(wrapper, "arg1", "arg2")

            assert.stub(function_opt).was_called_with("arg1", "arg2")
        end)

        it("should return opt return val", function()
            function_opt.returns("mock val")

            local ret = u.handle_function_opt(wrapper)

            assert.equals(ret, "mock val")
        end)

        it("should return copy of table opt", function()
            local table_opt = { key = "val" }

            local ret = u.handle_function_opt(table_opt)

            assert.is_not.equals(ret, table_opt)
            assert.same(ret, table_opt)
        end)

        it("should return non-function opt", function()
            local opt = 1

            local ret = u.handle_function_opt(opt)

            assert.equals(ret, opt)
        end)
    end)

    describe("get_root", function()
        local get_client = stub(require("null-ls.client"), "get_client")
        local nvim_buf_get_name = stub(vim.api, "nvim_buf_get_name")

        before_each(function()
            nvim_buf_get_name.returns("")
        end)

        after_each(function()
            get_client.returns(nil)
            get_client:clear()

            nvim_buf_get_name:clear()
        end)

        it("should get root from client", function()
            get_client.returns({ config = { root_dir = "client_root" } })

            local root = u.get_root()

            assert.equals(root, "client_root")
        end)

        it("should get root from config", function()
            nvim_buf_get_name.returns(test_utils.test_dir)

            local root = u.get_root()

            assert.equals(root, c.get().root_dir(test_utils.test_dir))
        end)

        it("should fall back to cwd", function()
            local root = u.get_root()

            assert.equals(root, vim.loop.cwd())
        end)
    end)
end)
