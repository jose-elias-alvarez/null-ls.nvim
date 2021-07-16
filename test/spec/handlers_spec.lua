local stub = require("luassert.stub")

local diagnostics = require("null-ls.diagnostics")
local code_actions = require("null-ls.code-actions")
local formatting = require("null-ls.formatting")
local methods = require("null-ls.methods")

local lsp = vim.lsp

describe("handlers", function()
    local handlers = require("null-ls.handlers")

    describe("setup", function()
        it("should replace lsp handlers with overrides on setup", function()
            handlers.setup()

            assert.equals(lsp.handlers["textDocument/codeAction"], handlers.code_action_handler)
        end)
    end)
end)
