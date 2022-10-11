local stub = require("luassert.stub")

local methods = require("null-ls.methods")
local test_utils = require("null-ls.utils.test")

describe("make_params", function()
    local u = require("null-ls.utils")

    local mock_method = "mockMethod"
    local mock_content = "I am some other content"

    before_each(function()
        test_utils.edit_test_file("test-file.lua")
    end)
    after_each(function()
        vim.cmd("bufdo! bwipeout!")
    end)

    it("should create params table from LSP params", function()
        local lsp_params = {
            client_id = 1,
            method = methods.lsp.CODE_ACTION,
            options = { "my option" },
        }

        local params = u.make_params(lsp_params, mock_method)

        assert.equals(params.client_id, lsp_params.client_id)
        assert.equals(params.lsp_method, lsp_params.method)
        assert.equals(params.lsp_params, lsp_params)
        assert.equals(params.options, lsp_params.options)
        assert.equals(params.method, mock_method)
        assert.equals(params.bufnr, vim.api.nvim_get_current_buf())
        -- lazily resolved keys
        assert.same(params.content, { 'print("I am a test file!")', "" })
        assert.equals(params.ft, "lua")
        assert.equals(params.filetype, "lua")
        assert.equals(params.col, 0)
        assert.equals(params.row, 1)
        assert.equals(params.bufname, test_utils.test_dir .. "/files/test-file.lua")
    end)

    it("should correctly resolve lazy keys", function()
        local params = u.make_params({}, mock_method)

        assert.same(params.content, { 'print("I am a test file!")', "" })
        assert.equals(params.ft, "lua")
        assert.equals(params.filetype, "lua")
        assert.same(params._pos, { 1, 0 })
        assert.equals(params.col, 0)
        assert.equals(params.row, 1)
        assert.equals(params.bufname, test_utils.test_dir .. "/files/test-file.lua")
    end)

    describe("range", function()
        it("should set range to converted LSP range", function()
            local lsp_params = {
                range = {
                    ["start"] = { line = 4, character = 0 },
                    ["end"] = { line = 5, character = 6 },
                },
            }

            local params = u.make_params(lsp_params)

            assert.truthy(params.range)
            assert.same(params.range, u.range.from_lsp(lsp_params.range))
        end)

        it("should throw if LSP params has no range", function()
            assert.has_error(function()
                local params = u.make_params({})

                print(params.range) -- index access should throw
            end)
        end)
    end)

    it("should set word_to_complete from cursor position", function()
        vim.cmd("normal 5l") -- move cursor to end of "print"

        local params = u.make_params({})

        assert.equals(params.word_to_complete, "print")
    end)

    describe("methods", function()
        local get_source = stub(require("null-ls.sources"), "get")

        local mock_source = { config = { my_key = "my_val" } }
        local mock_source_id = 1

        local params
        before_each(function()
            params = u.make_params({})
            params.source_id = mock_source_id

            get_source.returns({ mock_source })
        end)

        after_each(function()
            get_source:clear()
        end)

        describe("get_source", function()
            it("should throw if no source found", function()
                get_source.returns(nil)

                assert.has_error(function()
                    params:get_source()
                end)
            end)

            it("should call sources.get with source_id", function()
                params:get_source()

                assert.stub(get_source).was_called_with({ id = mock_source_id })
            end)

            it("should return found source", function()
                local source = params:get_source()

                assert.equals(source, mock_source)
            end)
        end)

        describe("get_config", function()
            it("should return source config", function()
                local config = params:get_config()

                assert.equals(config, mock_source.config)
            end)

            it("should return empty table if source has no config", function()
                get_source.returns({ { config = nil } })

                local config = params:get_source()

                assert.same(config, {})
            end)
        end)
    end)

    describe("resolve_bufnr", function()
        it("should resolve bufnr from params", function()
            local lsp_params = {
                bufnr = 111,
            }

            local params = u.make_params(lsp_params, mock_method)

            assert.equals(params.bufnr, lsp_params.bufnr)
        end)

        it("should resolve bufnr from uri", function()
            local lsp_params = {
                -- TODO: stub this out
                textDocument = { uri = vim.uri_from_bufnr(vim.api.nvim_get_current_buf()) },
            }

            local params = u.make_params(lsp_params, mock_method)

            assert.equals(params.bufnr, vim.api.nvim_get_current_buf())
        end)

        it("should fall back to current bufnr", function()
            local params = u.make_params({}, mock_method)

            assert.equals(params.bufnr, vim.api.nvim_get_current_buf())
        end)
    end)

    describe("resolve_content", function()
        it("should resolve content from LSP params on DID_OPEN", function()
            local lsp_params = {
                method = methods.lsp.DID_OPEN,
                textDocument = { text = "did open text" },
            }

            local params = u.make_params(lsp_params, mock_method)

            assert.same(params.content, { lsp_params.textDocument.text })
        end)

        it("should resolve content from params on DID_CHANGE", function()
            local lsp_params = {
                method = methods.lsp.DID_CHANGE,
                contentChanges = { { text = "did change text" } },
            }

            local params = u.make_params(lsp_params, mock_method)

            assert.same(params.content, { lsp_params.contentChanges[1].text })
        end)

        it("should directly get content from buffer if method does not match", function()
            local lsp_params = {
                method = "otherMethod",
                contentChanges = { { text = mock_content } },
            }

            local params = u.make_params(lsp_params, mock_method)

            assert.same(params.content, { 'print("I am a test file!")', "" })
        end)
    end)
end)
