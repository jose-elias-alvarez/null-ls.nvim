local diagnostics = require("null-ls.builtins.diagnostics")
local formatting = require("null-ls.builtins.formatting")
local code_actions = require("null-ls.builtins.code-actions")
local test = require("null-ls.builtins.test")

return { diagnostics = diagnostics, formatting = formatting, code_actions = code_actions, _test = test }
