local stub = require("luassert.stub")

local builtins = require("null-ls.builtins")
local c = require("null-ls.config")
local methods = require("null-ls.methods")
local sources = require("null-ls.sources")

local api = vim.api

describe("info", function()
    local info = require("null-ls.info")
    after_each(function()
        sources.reset()
        c.reset()
        vim.bo.filetype = ""
    end)

    describe("get_active_sources", function()
        before_each(function()
            vim.bo.filetype = "text"
            sources.register({
                builtins._test.mock_hover,
                builtins._test.first_formatter,
                builtins._test.second_formatter,
                -- filetype doesn't match
                builtins._test.mock_code_action,
            })
        end)

        it("should get table of active sources indexed by method", function()
            local active = info.get_active_sources()
            assert.truthy(active[methods.internal.HOVER])
            assert.truthy(active[methods.internal.FORMATTING])
            assert.truthy(#active[methods.internal.HOVER] == 1)
            assert.truthy(#active[methods.internal.FORMATTING] == 2)
        end)
    end)

    describe("show_window", function()
        local get_client = stub(require("null-ls.client"), "get_client")
        local buf_is_attached = stub(vim.lsp, "buf_is_attached")
        before_each(function()
            get_client.returns({})
            buf_is_attached.returns(true)
        end)
        after_each(function()
            get_client:clear()
        end)

        before_each(function()
            vim.bo.filetype = "text"
            sources.register({
                -- order of active sources is not fixed,
                -- so we have to avoid using more methods to assert against window content
                builtins._test.first_formatter,
                builtins._test.second_formatter,
            })
        end)

        it("should create window with log message and active sources", function()
            info.show_window()

            local bufnr = api.nvim_win_get_buf(0)
            assert.equals(api.nvim_buf_get_option(bufnr, "buftype"), "nofile")
            assert.equals(api.nvim_buf_get_option(bufnr, "filetype"), "null-ls-info")
            assert.equals(api.nvim_buf_get_option(bufnr, "modifiable"), false)

            local content = api.nvim_buf_get_lines(bufnr, 0, -1, false)
            assert.equals(
                content[1],
                "null-ls log: not enabled (this is normal; see the README if you need to enable logging)"
            )
            assert.equals(content[2], "Detected filetype: text")
            assert.equals(content[3], "")
            assert.equals(content[4], "2 source(s) active for this buffer:")
            assert.equals(content[5], "")
            assert.equals(content[6], "Formatting: anonymous source, anonymous source")
        end)

        it("should show log path when debug option is enabled", function()
            c._set({ debug = true })

            info.show_window()

            local content = api.nvim_buf_get_lines(api.nvim_win_get_buf(0), 0, -1, false)
            assert.equals(content[1], "null-ls log: " .. vim.fn.stdpath("cache") .. "/null-ls.log")
        end)
    end)
end)
