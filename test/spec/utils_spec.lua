local stub = require("luassert.stub")

local c = require("null-ls.config")
local methods = require("null-ls.methods")

local test_utils = require("test.utils")

describe("utils", function()
    local u = require("null-ls.utils")

    after_each(function()
        c.reset()
    end)

    describe("echo", function()
        local echo
        before_each(function()
            echo = stub(vim.api, "nvim_echo")
        end)
        after_each(function()
            echo:revert()
        end)

        it("should call nvim_echo with formatted args", function()
            local hlgroup = "MockHlgroup"
            u.echo(hlgroup, "message goes here")

            assert.stub(echo).was_called_with({ { "null-ls: message goes here", hlgroup } }, true, {})
        end)
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

    describe("debug_log", function()
        local logger
        before_each(function()
            logger = stub(require("null-ls.logger"), "debug")
        end)
        after_each(function()
            logger:revert()
        end)

        it("should do nothing if debug option is not set", function()
            u.debug_log("my message")

            assert.stub(logger).was_not_called()
        end)

        it("should call logger with message if debug option is set", function()
            c._set({ debug = true })

            u.debug_log("my message")

            assert.stub(logger).was_called_with("my message")
        end)
    end)

    describe("get_client", function()
        local get_active_clients
        before_each(function()
            get_active_clients = stub(vim.lsp, "get_active_clients")
        end)
        after_each(function()
            get_active_clients:revert()
        end)

        it("should return matching client", function()
            local client = { name = "null-ls" }
            get_active_clients.returns({ client })

            local found_client = u.get_client()

            assert.truthy(found_client)
            assert.equals(found_client, client)
        end)

        it("should nil if no client matches", function()
            local client = { name = "other-client" }
            get_active_clients.returns({ client })

            local found_client = u.get_client()

            assert.falsy(found_client)
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
                after_each(function()
                    vim.bo.fileformat = "unix"
                end)

                it("should directly get content from buffer on DID_OPEN", function()
                    vim.bo.fileformat = "dos"

                    local params = u.make_params({
                        method = methods.lsp.DID_OPEN,
                        textDocument = { text = mock_content },
                    }, mock_method)

                    assert.same(params.content, { 'print("I am a test file!")', "" })
                end)

                it("should directly get content from buffer on DID_CHANGE", function()
                    vim.bo.fileformat = "dos"

                    local params = u.make_params({
                        method = methods.lsp.DID_CHANGE,
                        contentChanges = { { text = mock_content } },
                    }, mock_method)

                    assert.same(params.content, { 'print("I am a test file!")', "" })
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
            assert.truthy(type(utils.root_has_file) == "function")
            assert.truthy(type(utils.root_matches) == "function")
        end)

        describe("root_has_file", function()
            it("should return true if file exists at root", function()
                assert.truthy(utils.root_has_file("stylua.toml"))
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

    describe("resolve_handler", function()
        local method = methods.lsp.FORMATTING
        local original_handler = vim.lsp.handlers[method]

        local get_client
        before_each(function()
            get_client = stub(u, "get_client")
            vim.lsp.handlers[method] = "default-handler"
        end)
        after_each(function()
            get_client:revert()
            vim.lsp.handlers[method] = original_handler
        end)

        it("should get handler from client when available", function()
            local mock_client = { handlers = { [method] = "custom-handler" } }
            get_client.returns(mock_client)

            local resolved = u.resolve_handler(method)

            assert.equals(resolved, "custom-handler")
        end)

        it("should get default handler when client handler is not set", function()
            local mock_client = { handlers = { ["otherMethod"] = "custom-handler" } }
            get_client.returns(mock_client)

            local resolved = u.resolve_handler(method)

            assert.equals(resolved, "default-handler")
        end)

        it("should get default handler when client is unavailable", function()
            get_client.returns(nil)

            local resolved = u.resolve_handler(method)

            assert.equals(resolved, "default-handler")
        end)
    end)
end)
