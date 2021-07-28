local diagnostics = require("null-ls.builtins.diagnostics")

describe("diagnostics", function()
    describe("write-good", function()
        local linter = diagnostics.write_good
        local parser = linter._opts.on_output
        local file = {
            [[Any rule whose heading is ~~struck through~~ is deprecated, but still provided for backward-compatibility.]],
        }

        it("should create a diagnostic", function()
            local output = [[rules.md:1:46:"is deprecated" may be passive voice]]
            local diagnostic = parser(output, { content = file })
            assert.are.same({
                row = "1", --
                col = "46",
                end_col = 58,
                severity = 1,
                message = '"is deprecated" may be passive voice',
            }, diagnostic)
        end)
    end)

    describe("markdownlint", function()
        local linter = diagnostics.markdownlint
        local parser = linter._opts.on_output
        local file = {
            [[<a name="md001"></a>]],
            [[]],
        }

        it("should create a diagnostic with a column", function()
            local output = "rules.md:1:1 MD033/no-inline-html Inline HTML [Element: a]"
            local diagnostic = parser(output, { content = file })
            assert.are.same({
                row = "1", --
                col = "1",
                severity = 1,
                message = "Inline HTML [Element: a]",
            }, diagnostic)
        end)
        it("should create a diagnostic without a column", function()
            local output =
                "rules.md:2 MD012/no-multiple-blanks Multiple consecutive blank lines [Expected: 1; Actual: 2]"
            local diagnostic = parser(output, { content = file })
            assert.are.same({
                row = "2", --
                severity = 1,
                message = "Multiple consecutive blank lines [Expected: 1; Actual: 2]",
            }, diagnostic)
        end)
    end)

    describe("teal", function()
        local linter = diagnostics.teal
        local parser = linter._opts.on_output
        local file = {
            [[require("settings").load_options()]],
            "vim.cmd [[",
        }

        it("should create a diagnostic (quote field is between quotes)", function()
            local output = [[init.lua:1:8: module not found: 'settings']]
            local diagnostic = parser(output, { content = file })
            assert.are.same({
                row = "1", --
                col = "8",
                end_col = 17,
                severity = 1,
                message = "module not found: 'settings'",
            }, diagnostic)
        end)
        it("should create a diagnostic (quote field is not between quotes)", function()
            local output = [[init.lua:2:1: unknown variable: vim]]
            local diagnostic = parser(output, { content = file })
            assert.are.same({
                row = "2", --
                col = "1",
                end_col = 3,
                severity = 1,
                message = "unknown variable: vim",
            }, diagnostic)
        end)
    end)

    describe("shellcheck", function()
        local linter = diagnostics.shellcheck
        local parser = linter._opts.on_output

        it("should create a diagnostic with info severity", function()
            local output = vim.fn.json_decode(
                [[ [{"file":"./OpenCast.sh","line":21,"endLine":21,"column":8,"endColumn":37,"level":"info","code":1091,"message":"Not following: script/cli_builder.sh was not specified as input (see shellcheck -x).","fix":null}] ]]
            )
            local diagnostic = parser({ output = output })
            assert.are.same({
                {
                    row = 21, --
                    end_row = 21,
                    col = 8,
                    end_col = 37,
                    severity = 3,
                    message = "Not following: script/cli_builder.sh was not specified as input (see shellcheck -x).",
                },
            }, diagnostic)
        end)
        it("should create a diagnostic with style severity", function()
            local output = vim.fn.json_decode(
                [[ [{"file":"./OpenCast.sh","line":21,"endLine":21,"column":8,"endColumn":37,"level":"style","code":1091,"message":"Not following: script/cli_builder.sh was not specified as input (see shellcheck -x).","fix":null}] ]]
            )
            local diagnostic = parser({ output = output })
            assert.are.same({
                {
                    row = 21, --
                    end_row = 21,
                    col = 8,
                    end_col = 37,
                    severity = 4,
                    message = "Not following: script/cli_builder.sh was not specified as input (see shellcheck -x).",
                },
            }, diagnostic)
        end)
    end)

    describe("selene", function()
        local linter = diagnostics.selene
        local parser = linter._opts.on_output
        local file = {
            "vim.cmd [[",
            [[CACHE_PATH = vim.fn.stdpath "cache"]],
        }

        it("should create a diagnostic (quote is between backquotes)", function()
            local output = [[init.lua:1:1: error[undefined_variable]: `vim` is not defined]]
            local diagnostic = parser(output, { content = file })
            assert.are.same({
                row = "1", --
                col = "1",
                end_col = 3,
                severity = 1,
                code = "undefined_variable",
                message = "`vim` is not defined",
            }, diagnostic)
        end)
        it("should create a diagnostic (quote is not between backquotes)", function()
            local output =
                [[lua/default-config.lua:2:1: warning[unused_variable]: CACHE_PATH is defined, but never used]]
            local diagnostic = parser(output, { content = file })
            assert.are.same({
                row = "2", --
                col = "1",
                end_col = 10,
                severity = 2,
                code = "unused_variable",
                message = "CACHE_PATH is defined, but never used",
            }, diagnostic)
        end)
    end)

    describe("eslint", function()
        local linter = diagnostics.eslint
        local parser = linter._opts.on_output

        it("should create a diagnostic with warning severity", function()
            local output = vim.fn.json_decode([[ 
            [{
              "filePath": "/home/luc/Projects/Pi-OpenCast/webapp/src/index.js",
              "messages": [
                {
                  "ruleId": "quotes",
                  "severity": 1,
                  "message": "Strings must use singlequote.",
                  "line": 1,
                  "column": 19,
                  "nodeType": "Literal",
                  "messageId": "wrongQuotes",
                  "endLine": 1,
                  "endColumn": 26,
                  "fix": {
                    "range": [
                      18,
                      25
                    ],
                    "text": "'react'"
                  }
                }
              ]
            }] ]])
            local diagnostic = parser({ output = output })
            assert.are.same({
                {
                    row = 1, --
                    end_row = 1,
                    col = 19,
                    end_col = 26,
                    severity = 2,
                    code = "quotes",
                    message = "Strings must use singlequote.",
                },
            }, diagnostic)
        end)
        it("should create a diagnostic with error severity", function()
            local output = vim.fn.json_decode([[ 
            [{
              "filePath": "/home/luc/Projects/Pi-OpenCast/webapp/src/index.js",
              "messages": [
                {
                  "ruleId": "quotes",
                  "severity": 2,
                  "message": "Strings must use singlequote.",
                  "line": 1,
                  "column": 19,
                  "nodeType": "Literal",
                  "messageId": "wrongQuotes",
                  "endLine": 1,
                  "endColumn": 26,
                  "fix": {
                    "range": [
                      18,
                      25
                    ],
                    "text": "'react'"
                  }
                }
              ]
            }] ]])
            local diagnostic = parser({ output = output })
            assert.are.same({
                {
                    row = 1, --
                    end_row = 1,
                    col = 19,
                    end_col = 26,
                    severity = 1,
                    code = "quotes",
                    message = "Strings must use singlequote.",
                },
            }, diagnostic)
        end)
    end)
end)
