local handlers = require("null-ls.handlers")
local diagnostics = require("null-ls.diagnostics")
local methods = require("null-ls.methods")
local helpers = require("null-ls.helpers")
local sources = require("null-ls.sources")

local lsp = vim.lsp

local M = {}

M.register = sources.register
M.attach = diagnostics.attach
M.methods = methods
M.helpers = helpers

M.setup = function()
    diagnostics.attach()
    lsp.buf_request = handlers.buf_request
    lsp.buf.execute_command = handlers.execute_command
end

return M
