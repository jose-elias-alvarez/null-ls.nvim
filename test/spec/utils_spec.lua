local stub = require("luassert.stub")

local methods = require("null-ls.methods")

local test_utils = require("test.utils")

describe("utils", function()
    local u = require("null-ls.utils")

    describe("echo", function()
        local echo
        before_each(function() echo = stub(vim.api, "nvim_echo") end)
        after_each(function() echo:revert() end)

        it("should call nvim_echo with formatted args", function()
            local hlgroup = "MockHlgroup"
            u.echo(hlgroup, "message goes here")

            assert.stub(echo).was_called_with(
                {{"null-ls: message goes here", hlgroup}}, true, {})
        end)
    end)

    describe("filetype_matches", function()
        it("should return true when handler.filetypes is nil", function()
            local handler = {filetypes = nil}
            local ft = "lua"

            local matches = u.filetype_matches(handler, ft)

            assert.equals(matches, true)
        end)

        it("should return true when handler.filetypes includes ft", function()
            local handler = {filetypes = {"lua"}}
            local ft = "lua"

            local matches = u.filetype_matches(handler, ft)

            assert.equals(matches, true)
        end)

        it("should return false when handler.filetypes does not include ft",
           function()
            local handler = {filetypes = {"javascript"}}
            local ft = "lua"

            local matches = u.filetype_matches(handler, ft)

            assert.equals(matches, false)
        end)
    end)

    describe("make_params", function()
        local mock_method = "mockMethod"
        after_each(function() vim.cmd("bufdo! bwipeout!") end)

        it("should return params from minimal original params", function()
            test_utils.edit_test_file("test-file.lua")

            local params = u.make_params(
                               {
                    bufnr = vim.api.nvim_get_current_buf(),
                    method = methods.lsp.CODE_ACTION
                }, mock_method)

            assert.equals(params.bufname,
                          test_utils.test_dir .. "/files/test-file.lua")
            assert.equals(params.uri, "file://" .. test_utils.test_dir ..
                              "/files/test-file.lua")
            assert.equals(params.lsp_method, methods.lsp.CODE_ACTION)
            assert.equals(params.bufnr, 1)
            assert.equals(params.col, 0)
            assert.equals(params.row, 1)
            assert.equals(params.ft, "lua")
            assert.equals(params.method, mock_method)
            assert.same(params.content, {"print(\"I am a test file!\")", "\n"})
        end)

        it("should get uri from original params", function()
            test_utils.edit_test_file("test-file.lua")

            local mock_uri = "file:///mock-file"
            local params = u.make_params({textDocument = {uri = mock_uri}},
                                         "mockMethod")

            assert.equals(params.uri, mock_uri)
        end)

        it("should get content from params on DID_OPEN", function()
            test_utils.edit_test_file("test-file.lua")

            local mock_content = "I am some other content"
            local params = u.make_params(
                               {
                    method = methods.lsp.DID_OPEN,
                    textDocument = {text = mock_content}
                }, "mockMethod")

            assert.same(params.content, {mock_content})
        end)

        it("should get content from params on DID_CHANGE", function()
            test_utils.edit_test_file("test-file.lua")

            local mock_content = "I am some other content"
            local params = u.make_params(
                               {
                    method = methods.lsp.DID_CHANGE,
                    contentChanges = {{text = mock_content}}
                }, "mockMethod")

            assert.same(params.content, {mock_content})
        end)
    end)

    describe("buf", function()
        after_each(function() vim.cmd("bufdo! bwipeout!") end)

        describe("content", function()
            before_each(function()
                test_utils.edit_test_file("test-file.lua")
                vim.api.nvim_buf_set_option(vim.api.nvim_get_current_buf(),
                                            "eol", true)
            end)

            it("should get buffer content as table", function()
                local content = u.buf.content()

                assert.equals(type(content), "table")
                assert.same(content, {"print(\"I am a test file!\")", "\n"})
            end)

            it("should not add final newline to table when eol option is false",
               function()
                vim.api.nvim_buf_set_option(vim.api.nvim_get_current_buf(),
                                            "eol", false)
                local content = u.buf.content()

                assert.same(content, {"print(\"I am a test file!\")"})
            end)

            it("should get buffer content as string", function()
                local content = u.buf.content(nil, true)

                assert.equals(type(content), "string")
                assert.equals(content, "print(\"I am a test file!\")\n")
            end)

            it(
                "should not add final newline to string when eol option is false",
                function()
                    vim.api.nvim_buf_set_option(vim.api.nvim_get_current_buf(),
                                                "eol", false)
                    local content = u.buf.content(nil, true)

                    assert.equals(content, "print(\"I am a test file!\")")
                end)
        end)
    end)

    describe("string", function()
        describe("replace", function()
            it("should return nil if string does not contain original",
               function()
                local str = "I am a string"
                local original = "xxxx"
                local replacement = "doesn't matter"

                local replaced = u.string.replace(str, original, replacement)

                assert.equals(replaced, nil)
            end)

            it(
                "should return replacement when string and original are identical",
                function()
                    local str = "I am a string"
                    local original = "I am a string"
                    local replacement = "I am something else"

                    local replaced = u.string
                                         .replace(str, original, replacement)

                    assert.equals(replaced, replacement)
                end)

            it("should replace original from start of string", function()
                local str = "I am a string"
                local original = "I am"
                local replacement = "You are"

                local replaced = u.string.replace(str, original, replacement)

                assert.equals(replaced, "You are a string")
            end)

            it("should replace original from end of string", function()
                local str = "I am a string"
                local original = "string"
                local replacement = "table"

                local replaced = u.string.replace(str, original, replacement)

                assert.equals(replaced, "I am a table")
            end)

            it("should replace original from middle of string", function()
                local str = "I am a string"
                local original = "am"
                local replacement = "am not"

                local replaced = u.string.replace(str, original, replacement)

                assert.equals(replaced, "I am not a string")
            end)
        end)

        describe("to_number_safe", function()
            it("should return default when str is nil", function()
                local str = nil
                local default = 5

                local num = u.string.to_number_safe(str, default)

                assert.equals(num, default)
            end)

            it("should return str converted to number", function()
                local str = "10"
                local default = 5

                local num = u.string.to_number_safe(str, default)

                assert.equals(num, 10)
            end)

            it("should return str converted and modified by offset", function()
                local str = "10"
                local default = 5
                local offset = 2

                local num = u.string.to_number_safe(str, default, offset)

                assert.equals(num, 12)
            end)
        end)
    end)
end)
