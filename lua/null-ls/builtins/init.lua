local diagnostics = require("null-ls.builtins.diagnostics")
local formatting = require("null-ls.builtins.formatting")
local code_actions = require("null-ls.builtins.code-actions")
local test = require("null-ls.builtins.test")

local builtin = { diagnostics = diagnostics, formatting = formatting, code_actions = code_actions, _test = test }

for _, builtins in pairs(builtin) do
    for name, b in pairs(builtins) do
        b.name = b.name or name
    end
end

return builtin
