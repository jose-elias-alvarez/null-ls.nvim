local mock = require("luassert.mock")
local stub = require("luassert.stub")

local methods = require("null-ls.methods")
local generators = require("null-ls.generators")
local u = require("null-ls.utils")
local s = require("null-ls.state")
local c = require("null-ls.config")

local diagnostic_api = mock(vim.diagnostic, "true")

describe("diagnostics", function()
    local diagnostics = require("null-ls.diagnostics")

    describe("handler", function()
        stub(s, "clear_cache")
        stub(s, "clear_commands")
        stub(u, "make_params")
        stub(generators, "run_registered")
        stub(vim, "uri_to_bufnr")
        stub(vim.api, "nvim_buf_is_valid")

        local mock_uri = "file:///mock-file"
        local mock_handler = stub.new()
        local mock_bufnr = 5
        local mock_source_id = 8141

        local mock_params, mock_generator
        before_each(function()
            mock_params = {
                textDocument = { uri = mock_uri, version = 1 },
                method = methods.lsp.DID_OPEN,
                bufnr = mock_bufnr,
            }
            mock_generator = {
                source_id = mock_source_id,
                multiple_files = nil,
            }
            mock_generator.opts = {}

            u.make_params.returns(mock_params)
            vim.uri_to_bufnr.returns(mock_bufnr)
            vim.api.nvim_buf_is_valid.returns(true)
        end)

        after_each(function()
            mock_handler:clear()

            s.clear_cache:clear()
            s.clear_commands:clear()
            generators.run_registered:clear()
            u.make_params:clear()
            vim.uri_to_bufnr:clear()
            vim.api.nvim_buf_is_valid:clear()

            s.reset()
            c.reset()
        end)

        it("should call clear_cache with uri and clear_commands with bufnr when method is DID_CLOSE", function()
            mock_params.method = methods.lsp.DID_CLOSE

            diagnostics.handler(mock_params)

            assert.stub(s.clear_cache).was_called_with(mock_params.textDocument.uri)
            assert.stub(s.clear_commands).was_called_with(vim.uri_to_bufnr(mock_params.textDocument.uri))
        end)

        it("should call clear_cache with uri when method is DID_CHANGE", function()
            mock_params.method = methods.lsp.DID_CHANGE

            diagnostics.handler(mock_params)

            assert.stub(s.clear_cache).was_called_with(mock_params.textDocument.uri)
        end)

        it("should call make_params with params and method", function()
            diagnostics.handler(mock_params)

            local refs = u.make_params.calls[1].refs

            assert.equals(refs[1].method, mock_params.method)
            assert.equals(refs[1].textDocument, mock_params.textDocument)
            assert.equals(refs[1].bufnr, mock_params.bufnr)
            assert.equals(refs[2], methods.internal.DIAGNOSTICS_ON_OPEN)
        end)

        it("should only run once if method is DID_SAVE and buffer did not change", function()
            local new_params = vim.deepcopy(mock_params)
            new_params.method = methods.lsp.DID_SAVE

            diagnostics.handler(new_params)
            diagnostics.handler(new_params)

            assert.stub(generators.run_registered).was_called(1)
        end)

        describe("handler", function()
            local mock_diagnostics = {
                [1] = { { message = "diagnostics", bufnr = 1 } },
                [2] = { { message = "more diagnostics", bufnr = 2 } },
            }

            before_each(function()
                diagnostic_api.set:clear()
            end)

            describe("changedtick tracking", function()
                it("should call handler on each callback if buffer did not change", function()
                    diagnostics.handler(mock_params)
                    diagnostics.handler(mock_params)

                    generators.run_registered.calls[1].refs[1].after_each(mock_diagnostics, mock_params, mock_generator)
                    generators.run_registered.calls[2].refs[1].after_each(mock_diagnostics, mock_params, mock_generator)

                    assert.stub(diagnostic_api.set).was_called(2)
                end)

                it("should call handler only once if buffer changed in between callbacks", function()
                    diagnostics.handler(mock_params)
                    generators.run_registered.calls[1].refs[1].after_each(mock_diagnostics, mock_params, mock_generator)

                    local new_params = vim.deepcopy(mock_params)
                    new_params.textDocument.version = 9999
                    diagnostics.handler(new_params)

                    generators.run_registered.calls[2].refs[1].after_each(mock_diagnostics, new_params, mock_generator)

                    assert.stub(diagnostic_api.set).was_called(1)
                end)

                it("should call handler on each callback if buffer changed but method is different", function()
                    diagnostics.handler(mock_params)
                    generators.run_registered.calls[1].refs[1].after_each(mock_diagnostics, mock_params, mock_generator)

                    local new_params = vim.deepcopy(mock_params)
                    new_params.textDocument.version = 9999
                    new_params.method = "newMethod"
                    diagnostics.handler(new_params)

                    generators.run_registered.calls[2].refs[1].after_each(mock_diagnostics, new_params, mock_generator)

                    assert.stub(diagnostic_api.set).was_called(2)
                end)
            end)

            describe("single-file diagnostics", function()
                local after_each
                before_each(function()
                    diagnostics.handler(mock_params)

                    after_each = generators.run_registered.calls[1].refs[1].after_each
                end)

                it("should send results of diagnostic generators to API handler", function()
                    for id, diags in pairs(mock_diagnostics) do
                        mock_generator.source_id = id
                        after_each(diags, mock_params, mock_generator)
                    end

                    assert.stub(diagnostic_api.set).was_called(#mock_diagnostics)
                    for id in pairs(mock_diagnostics) do
                        assert.stub(diagnostic_api.set).was_called_with(
                            diagnostics.get_namespace(id),
                            mock_bufnr,
                            mock_diagnostics[id]
                        )
                    end
                end)
            end)

            describe("multiple-file diagnostics", function()
                local after_each
                before_each(function()
                    vim.diagnostic.get.returns({})

                    mock_generator.multiple_files = true
                    diagnostics.handler(mock_params)

                    after_each = generators.run_registered.calls[1].refs[1].after_each
                end)

                it("should send results of diagnostic generators to API handler", function()
                    for id, diags in pairs(mock_diagnostics) do
                        mock_generator.source_id = id
                        after_each(diags, mock_params, mock_generator)
                    end

                    assert.stub(diagnostic_api.set).was_called(#mock_diagnostics)
                    for id in pairs(mock_diagnostics) do
                        assert.stub(diagnostic_api.set).was_called_with(
                            diagnostics.get_namespace(id),
                            mock_diagnostics[id][1].bufnr,
                            mock_diagnostics[id]
                        )
                    end
                end)

                it("should clear stale diagnostics", function()
                    local old_diagnostics = {
                        { bufnr = 9999 },
                    }
                    vim.diagnostic.get.returns(old_diagnostics)

                    for id, diags in pairs(mock_diagnostics) do
                        mock_generator.source_id = id
                        after_each(diags, mock_params, mock_generator)
                    end

                    -- twice per old diagnostic
                    assert.stub(diagnostic_api.set).was_called(#mock_diagnostics + 2)
                    for id in pairs(mock_diagnostics) do
                        assert.stub(diagnostic_api.set).was_called_with(
                            diagnostics.get_namespace(id),
                            old_diagnostics[1].bufnr,
                            {}
                        )
                    end
                end)

                it("should not send results if diagnostic.bufnr is not set", function()
                    for id, diags in pairs(mock_diagnostics) do
                        for _, diag in ipairs(diags) do
                            diag.bufnr = nil
                        end
                        mock_generator.source_id = id
                        after_each(diags, mock_params, mock_generator)
                    end

                    assert.stub(diagnostic_api.set).was_called(0)
                end)
            end)
        end)

        describe("postprocess", function()
            local bufadd = stub(vim.fn, "bufadd")

            local postprocess, mock_diagnostic
            before_each(function()
                bufadd.returns(mock_bufnr)

                mock_diagnostic = {
                    row = 1,
                    col = 5,
                    end_row = 2,
                    end_col = 6,
                    source = "source",
                    message = "message",
                    code = "code",
                    severity = vim.diagnostic.severity.WARN,
                }
                u.make_params.returns({ uri = mock_params.textDocument.uri })

                diagnostics.handler(mock_params)
                postprocess = generators.run_registered.calls[1].refs[1].postprocess
            end)

            before_each(function()
                c.reset()
                bufadd:clear()
            end)

            it("should convert range when all positions are defined", function()
                local diagnostic = { row = 1, col = 5, end_row = 2, end_col = 6 }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.equals(diagnostic.lnum, 0)
                assert.equals(diagnostic.end_lnum, 1)
                assert.equals(diagnostic.col, 4)
                assert.equals(diagnostic.end_col, 5)
            end)

            it("should convert range when row is missing", function()
                local diagnostic = {
                    row = nil,
                    col = 5,
                    end_row = 2,
                    end_col = 6,
                }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.equals(diagnostic.lnum, 0)
                assert.equals(diagnostic.end_lnum, 1)
                assert.equals(diagnostic.col, 4)
                assert.equals(diagnostic.end_col, 5)
            end)

            it("should convert range when col is missing", function()
                local diagnostic = {
                    row = 1,
                    col = nil,
                    end_row = 2,
                    end_col = 6,
                }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.equals(diagnostic.lnum, 0)
                assert.equals(diagnostic.end_lnum, 1)
                assert.equals(diagnostic.col, 0)
                assert.equals(diagnostic.end_col, 5)
            end)

            it("should convert range when end_row is missing", function()
                local diagnostic = {
                    row = 1,
                    col = 5,
                    end_row = nil,
                    end_col = 6,
                }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.equals(diagnostic.lnum, 0)
                assert.equals(diagnostic.end_lnum, 0)
                assert.equals(diagnostic.col, 4)
                assert.equals(diagnostic.end_col, 5)
            end)

            it("should convert range when end_col is missing", function()
                local diagnostic = {
                    row = 1,
                    col = 5,
                    end_row = 2,
                    end_col = nil,
                }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.equals(diagnostic.lnum, 0)
                assert.equals(diagnostic.end_lnum, 1)
                assert.equals(diagnostic.col, 4)
                assert.equals(diagnostic.end_col, 0)
            end)

            it("should convert range when all positions are missing", function()
                local diagnostic = {
                    row = nil,
                    col = nil,
                    end_row = nil,
                    end_col = nil,
                }

                postprocess(diagnostic, mock_params, mock_generator)

                assert.equals(diagnostic.lnum, 0)
                assert.equals(diagnostic.end_lnum, 1)
                assert.equals(diagnostic.col, 0)
                assert.equals(diagnostic.end_col, 0)
            end)

            it("should keep diagnostic source when defined", function()
                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.equals(mock_diagnostic.source, "source")
            end)

            it("should set source from generator name", function()
                mock_diagnostic.source = nil
                mock_generator.opts.name = "generator-source"

                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.equals(mock_diagnostic.source, "generator-source")
            end)

            it("should set source from generator command", function()
                mock_diagnostic.source = nil
                mock_generator.opts.command = "generator-source"

                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.equals(mock_diagnostic.source, "generator-source")
            end)

            it("should set default source when undefined in diagnostic and generator", function()
                mock_diagnostic.source = nil
                mock_generator.opts = {}

                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.equals(mock_diagnostic.source, "null-ls")
            end)

            it("should return message with default format", function()
                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.equals(mock_diagnostic.message, "message")
            end)

            it("should format message from global format", function()
                c._set({ diagnostics_format = "[#{c}] #{m} (#{s})" })

                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.equals(mock_diagnostic.message, "[code] message (source)")
            end)

            it("should format message from generator format", function()
                mock_generator.opts.diagnostics_format = "#{c}! #{m} [#{s}]"

                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.equals(mock_diagnostic.message, "code! message [source]")
            end)

            it("should set bufnr from filename", function()
                mock_diagnostic.filename = "mock-file"

                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.stub(bufadd).was_called_with(mock_diagnostic.filename)
                assert.equals(mock_diagnostic.bufnr, mock_bufnr)
            end)

            it("should not override bufnr when set", function()
                mock_diagnostic.filename = "mock-file"
                mock_diagnostic.bufnr = mock_bufnr

                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.stub(bufadd).was_not_called()
                assert.equals(mock_diagnostic.bufnr, mock_bufnr)
            end)

            it("should keep diagnostic severity when set", function()
                local starting_severity = mock_diagnostic.severity

                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.equals(starting_severity, mock_diagnostic.severity)
            end)

            it("should set severity to fallback when not set", function()
                mock_diagnostic.severity = nil

                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.truthy(mock_diagnostic.severity)
                assert.equals(mock_diagnostic.severity, c.get().fallback_severity)
            end)

            it("should pass diagnostic through diagnostics_postprocess", function()
                local called = false
                local mock_postprocess = function(diagnostic)
                    called = true
                    diagnostic.message = "postprocess"
                end
                mock_generator.opts = { diagnostics_postprocess = mock_postprocess }

                postprocess(mock_diagnostic, mock_params, mock_generator)

                assert.truthy(called)
                assert.equals(mock_diagnostic.message, "postprocess")
            end)
        end)
    end)

    describe("namespaces", function()
        local create_namespace = stub(vim.api, "nvim_create_namespace")
        local mock_namespace, mock_id = 5959, 4812

        before_each(function()
            create_namespace.returns(mock_namespace)
        end)
        after_each(function()
            create_namespace:clear()
            diagnostic_api.reset:clear()

            diagnostics._reset_namespaces()
        end)

        describe("get_namespace", function()
            it("should create and return namespace", function()
                local ns = diagnostics.get_namespace(mock_id)

                assert.stub(create_namespace).was_called_with("NULL_LS_SOURCE_" .. mock_id)
                assert.equals(ns, mock_namespace)
            end)

            it("should return namespace if already created", function()
                local ns = diagnostics.get_namespace(mock_id)
                ns = diagnostics.get_namespace(mock_id)

                assert.stub(create_namespace).was_called(1)
                assert.equals(ns, mock_namespace)
            end)
        end)

        describe("hide_source_diagnostics", function()
            it("should reset namespace diagnostics", function()
                local ns = diagnostics.get_namespace(mock_id)

                diagnostics.hide_source_diagnostics(mock_id)

                assert.stub(diagnostic_api.reset).was_called_with(ns)
            end)

            it("should not reset diagnostics if namespace does not exist", function()
                diagnostics.hide_source_diagnostics(mock_id)

                assert.stub(diagnostic_api.reset).was_not_called()
            end)
        end)
    end)
end)
