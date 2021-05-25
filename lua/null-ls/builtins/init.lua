local diagnostics = require("null-ls.builtins.diagnostics")
local formatting = require("null-ls.builtins.formatting")
local test = require("null-ls.builtins.test")

return {diagnostics = diagnostics, formatting = formatting, _test = test}
