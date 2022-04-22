local diagnostics = require("null-ls.builtins").diagnostics

describe("diagnostics", function()
    describe("buf", function()
        local linter = diagnostics.buf
        local parser = linter._opts.on_output

        it("should create a diagnostic with an Error severity", function()
            local file = {
                [[ syntax = "proto3"; package tutorial.v1;]],
            }
            local output =
                [[demo.proto:2:1:Files with package "tutorial.v1" must be within a directory "tutorial/v1" relative to root but were in directory ".".]]
            local diagnostic = parser(output, { content = file })
            assert.same({
                col = "1",
                filename = "demo.proto",
                message = [[Files with package "tutorial.v1" must be within a directory "tutorial/v1" relative to root but were in directory ".".]],
                row = "2",
            }, diagnostic)
        end)
    end)
    describe("chktex", function()
        local linter = diagnostics.chktex
        local parser = linter._opts.on_output
        local file = {
            [[\documentclass{article}]],
            [[\begin{document}]],
            [[Lorem ipsum dolor \sit amet]],
            [[\end{document}]],
        }

        it("should create a diagnostic", function()
            local output = [[3:23:1:Warning:1:Command terminated with space.]]
            local diagnostic = parser(output, { content = file })
            assert.same({
                code = "1",
                row = "3",
                col = "23",
                end_col = 24,
                severity = 2,
                message = "Command terminated with space.",
            }, diagnostic)
        end)
    end)

    describe("credo", function()
        local linter = diagnostics.credo
        local parser = linter._opts.on_output
        local credo_diagnostics
        local done = function(_diagnostics)
            credo_diagnostics = _diagnostics
        end
        after_each(function()
            credo_diagnostics = nil
        end)

        it("should create a diagnostic with error severity", function()
            local output = [[
            {
              "issues": [
                {
                  "category": "consistency",
                  "check": "Credo.Check.Consistency.SpaceInParentheses",
                  "column": null,
                  "column_end": null,
                  "filename": "lib/todo_web/controllers/page_controller.ex",
                  "line_no": 4,
                  "message": "There is no whitespace around parentheses/brackets most of the time, but here there is.",
                  "priority": 12,
                  "scope": "TodoWeb.PageController.index",
                  "trigger": "( c"
                }
              ]
            } ]]
            parser({ output = output }, done)
            assert.same({
                {
                    source = "credo",
                    message = "There is no whitespace around parentheses/brackets most of the time, but here there is.",
                    row = 4,
                    col = nil,
                    end_col = nil,
                    severity = 1,
                },
            }, credo_diagnostics)
        end)
        it("should create a diagnostic with warning severity", function()
            local output = [[
            {
              "issues": [{
                "category": "readability",
                "check": "Credo.Check.Readability.ImplTrue",
                "column": 3,
                "column_end": 13,
                "filename": "./foo.ex",
                "line_no": 3,
                "message": "@impl true should be @impl MyBehaviour",
                "priority": 8,
                "scope": null,
                "trigger": "@impl true"
              }]
            } ]]
            parser({ output = output }, done)
            assert.same({
                {
                    source = "credo",
                    message = "@impl true should be @impl MyBehaviour",
                    row = 3,
                    col = 3,
                    end_col = 13,
                    severity = 2,
                },
            }, credo_diagnostics)
        end)
        it("should create a diagnostic with information severity", function()
            local output = [[
            {
              "issues": [{
                "category": "design",
                "check": "Credo.Check.Design.TagTODO",
                "column": null,
                "column_end": null,
                "filename": "./foo.ex",
                "line_no": 8,
                "message": "Found a TODO tag in a comment: \"TODO: implement check\"",
                "priority": -5,
                "scope": null,
                "trigger": "TODO: implement check"
              }]
            } ]]
            parser({ output = output }, done)
            assert.same({
                {
                    source = "credo",
                    message = 'Found a TODO tag in a comment: "TODO: implement check"',
                    row = 8,
                    col = nil,
                    end_col = nil,
                    severity = 3,
                },
            }, credo_diagnostics)
        end)
        it("should create a diagnostic falling back to hint severity", function()
            local output = [[
            {
              "issues": [{
                "category": "refactor",
                "check": "Credo.Check.Refactor.FilterFilter",
                "column": null,
                "column_end": null,
                "filename": "./foo.ex",
                "line_no": 12,
                "message": "One `Enum.filter/2` is more efficient than `Enum.filter/2 |> Enum.filter/2`",
                "priority": -15,
                "scope": null,
                "trigger": "|>"
              }]
            } ]]
            parser({ output = output }, done)
            assert.same({
                {
                    source = "credo",
                    message = "One `Enum.filter/2` is more efficient than `Enum.filter/2 |> Enum.filter/2`",
                    row = 12,
                    col = nil,
                    end_col = nil,
                    severity = 4,
                },
            }, credo_diagnostics)
        end)
        it("returns errors as diagnostics", function()
            local error =
                [[** (Mix) The task "credo" could not be found\nNote no mix.exs was found in the current directory]]
            parser({ err = error }, done)
            assert.same({
                {
                    source = "credo",
                    message = error,
                    row = 1,
                },
            }, credo_diagnostics)
        end)
        it("should handle compile warnings preceeding output", function()
            local output = [[
            00:00:00.000 [warn] IMPORTING DEV.SECRET

            {
              "issues": [
                {
                  "category": "consistency",
                  "check": "Credo.Check.Consistency.SpaceInParentheses",
                  "column": null,
                  "column_end": null,
                  "filename": "lib/todo_web/controllers/page_controller.ex",
                  "line_no": 4,
                  "message": "There is no whitespace around parentheses/brackets most of the time, but here there is.",
                  "priority": 12,
                  "scope": "TodoWeb.PageController.index",
                  "trigger": "( c"
                }
              ]
            } ]]
            parser({ output = output }, done)
            assert.same({
                {
                    source = "credo",
                    message = "There is no whitespace around parentheses/brackets most of the time, but here there is.",
                    row = 4,
                    col = nil,
                    end_col = nil,
                    severity = 1,
                },
            }, credo_diagnostics)
        end)
        it("should handle messages with incomplete json", function()
            local output = [[Some incomplete message that shouldn't really happen { "issues": ]]
            parser({ output = output }, done)
            assert.same({
                {
                    source = "credo",
                    message = output,
                    row = 1,
                },
            }, credo_diagnostics)
        end)
        it("should handle messages without json", function()
            local output = [[Another message that shouldn't really happen]]
            parser({ output = output }, done)
            assert.same({
                {
                    source = "credo",
                    message = output,
                    row = 1,
                },
            }, credo_diagnostics)
        end)
    end)

    describe("luacheck", function()
        local linter = diagnostics.luacheck
        local parser = linter._opts.on_output
        local file = {
            [[sx = {]],
        }

        it("should create a diagnostic", function()
            local output = [[test.lua:2:1-1: (E011) expected expression near <eof>]]
            local diagnostic = parser(output, { content = file })
            assert.same({
                code = "011",
                row = "2",
                col = "1",
                end_col = 2,
                severity = 1,
                message = "expected expression near <eof>",
            }, diagnostic)
        end)
    end)

    describe("write-good", function()
        local linter = diagnostics.write_good
        local parser = linter._opts.on_output
        local file = {
            [[Any rule whose heading is ~~struck through~~ is deprecated, but still provided for backward-compatibility.]],
        }

        it("should create a diagnostic", function()
            local output = [[rules.md:1:46:"is deprecated" may be passive voice]]
            local diagnostic = parser(output, { content = file })
            assert.same({
                row = "1",
                col = 47,
                end_col = 59,
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
            assert.same({
                code = "MD033/no-inline-html",
                row = "1",
                col = "1",
                message = "Inline HTML [Element: a]",
            }, diagnostic)
        end)
        it("should create a diagnostic without a column", function()
            local output =
                "rules.md:2 MD012/no-multiple-blanks Multiple consecutive blank lines [Expected: 1; Actual: 2]"
            local diagnostic = parser(output, { content = file })
            assert.same({
                row = "2",
                code = "MD012/no-multiple-blanks",
                message = "Multiple consecutive blank lines [Expected: 1; Actual: 2]",
            }, diagnostic)
        end)
    end)

    describe("mdl", function()
        local linter = diagnostics.mdl
        local parser = linter._opts.on_output

        it("should create a diagnostic", function()
            local output = vim.json.decode([[
              [
                {
                  "filename": "rules.md",
                  "line": 1,
                  "rule": "MD022",
                  "aliases": [
                    "blanks-around-headers"
                  ],
                  "description": "Headers should be surrounded by blank lines"
                }
              ]
            ]])
            local diagnostic = parser({ output = output })
            assert.same({
                {
                    code = "MD022",
                    row = 1,
                    severity = 2,
                    message = "Headers should be surrounded by blank lines",
                },
            }, diagnostic)
        end)
    end)

    describe("tl check", function()
        local linter = diagnostics.teal
        local parser = linter._opts.on_output
        local file = {
            [[require("settings").load_options()]],
            "vim.cmd [[ ]]",
            "local b = 3 + 34",
        }
        local output = table.concat({
            "1 warning:",
            "tmp.tl:3:7: unused variable b: integer",
            "2 errors:",
            "tmp.tl:1:8: module not found: 'settings'",
            "tmp.tl:2:1: unknown variable: vim",
        }, "\n")

        local teal_diagnostics = nil
        local function done(_diagnostics)
            teal_diagnostics = _diagnostics
        end
        parser({ content = file, output = output, temp_path = "tmp.tl" }, done)

        it("should create a diagnostic with a warning severity (no quote)", function()
            assert.same({
                row = "3",
                col = "7",
                message = "unused variable b: integer",
                severity = 2,
            }, teal_diagnostics[1])
        end)
        it("should create a diagnostic with an error severity (quote field is between quotes)", function()
            assert.same({
                row = "1",
                col = "8",
                end_col = 18,
                message = "module not found: 'settings'",
                severity = 1,
            }, teal_diagnostics[2])
        end)
        it("should create a diagnostic with an error severity (quote field is not between quotes)", function()
            assert.same({
                row = "2",
                col = "1",
                end_col = 4,
                message = "unknown variable: vim",
                severity = 1,
            }, teal_diagnostics[3])
        end)
    end)

    describe("shellcheck", function()
        local linter = diagnostics.shellcheck
        local parser = linter._opts.on_output

        it("should create a diagnostic with info severity", function()
            local output = vim.json.decode([[
            {
              "comments": [{
                "file": "./OpenCast.sh",
                "line": 21,
                "endLine": 21,
                "column": 8,
                "endColumn": 37,
                "level": "info",
                "code": 1091,
                "message": "Not following: script/cli_builder.sh was not specified as input (see shellcheck -x).",
                "fix": null
              }]
            } ]])
            local diagnostic = parser({ output = output })
            assert.same({
                {
                    code = 1091,
                    row = 21,
                    end_row = 21,
                    col = 8,
                    end_col = 37,
                    severity = 3,
                    message = "Not following: script/cli_builder.sh was not specified as input (see shellcheck -x).",
                },
            }, diagnostic)
        end)
        it("should create a diagnostic with style severity", function()
            local output = vim.json.decode([[
            {
              "comments": [{
                "file": "./OpenCast.sh",
                "line": 21,
                "endLine": 21,
                "column": 8,
                "endColumn": 37,
                "level": "style",
                "code": 1091,
                "message": "Not following: script/cli_builder.sh was not specified as input (see shellcheck -x).",
                "fix": null
              }]
            } ]])
            local diagnostic = parser({ output = output })
            assert.same({
                {
                    code = 1091,
                    row = 21,
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
            assert.same({
                row = "1",
                col = "1",
                end_col = 4,
                severity = 1,
                code = "undefined_variable",
                message = "`vim` is not defined",
            }, diagnostic)
        end)
        it("should create a diagnostic (quote is not between backquotes)", function()
            local output =
                [[lua/default-config.lua:2:1: warning[unused_variable]: CACHE_PATH is defined, but never used]]
            local diagnostic = parser(output, { content = file })
            assert.same({
                row = "2",
                col = "1",
                end_col = 11,
                severity = 2,
                code = "unused_variable",
                message = "CACHE_PATH is defined, but never used",
            }, diagnostic)
        end)
    end)

    describe("solhint", function()
        local linter = diagnostics.solhint
        local parser = linter._opts.on_output

        it("should create a diagnostic with an Error severity", function()
            local file = {
                [[ import 'interfaces/IToken.sol'; ]],
            }
            local output = "contracts/Token.sol:22:8: Use double quotes for string literals [Error/quotes]"
            local diagnostic = parser(output, { content = file })
            assert.same({
                code = "quotes",
                col = "8",
                filename = "contracts/Token.sol",
                message = "Use double quotes for string literals",
                row = "22",
                severity = 1,
            }, diagnostic)
        end)

        it("should create a diagnostic with a Warning severity", function()
            local file = {
                [[ function somethingPrivate(uint8 id) returns (bool) {}; ]],
            }
            local output = "contracts/Token.sol:359:5: Explicitly mark visibility in function [Warning/func-visibility]"
            local diagnostic = parser(output, { content = file })
            assert.same({
                code = "func-visibility",
                col = "5",
                filename = "contracts/Token.sol",
                message = "Explicitly mark visibility in function",
                row = "359",
                severity = 2,
            }, diagnostic)
        end)
    end)

    describe("eslint", function()
        local linter = diagnostics.eslint
        local parser = linter._opts.on_output

        it("should create a diagnostic with warning severity", function()
            local output = vim.json.decode([[
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
            assert.same({
                {
                    row = 1,
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
            local output = vim.json.decode([[
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
            assert.same({
                {
                    row = 1,
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

    describe("standardjs", function()
        local linter = diagnostics.standardjs
        local parser = linter._opts.on_output

        it("should create a diagnostic with error severity", function()
            local file = {
                [[export const foo = () => { return 'hello']],
            }
            local output = [[rules.js:1:2: Parsing error: Unexpected token]]
            local diagnostic = parser(output, { content = file })
            assert.same({
                row = "1",
                col = "2",
                severity = 1,
                message = "Unexpected token",
            }, diagnostic)
        end)
        it("should create a diagnostic with warning severity", function()
            local file = {
                [[export const foo = () => { return "hello" }]],
            }
            local output = [[rules.js:1:35: Strings must use singlequote.]]
            local diagnostic = parser(output, { content = file })
            assert.same({
                row = "1",
                col = "35",
                severity = 2,
                message = "Strings must use singlequote.",
            }, diagnostic)
        end)
    end)

    describe("hadolint", function()
        local linter = diagnostics.hadolint
        local parser = linter._opts.on_output

        it("should create a diagnostic with warning severity", function()
            local output = vim.json.decode([[
                  [{
                    "line": 24,
                    "code": "DL3008",
                    "message": "Pin versions in apt get install. Instead of `apt-get install <package>` use `apt-get install <package>=<version>`",
                    "column": 1,
                    "file": "/home/luc/Projects/Test/buildroot/support/docker/Dockerfile",
                    "level": "warning"
                  }]
            ]])
            local diagnostic = parser({ output = output })
            assert.same({
                {
                    row = 24,
                    col = 1,
                    severity = 2,
                    code = "DL3008",
                    message = "Pin versions in apt get install. Instead of `apt-get install <package>` use `apt-get install <package>=<version>`",
                },
            }, diagnostic)
        end)
        it("should create a diagnostic with info severity", function()
            local output = vim.json.decode([[
                  [{
                    "line": 24,
                    "code": "DL3059",
                    "message": "Multiple consecutive `RUN` instructions. Consider consolidation.",
                    "column": 1,
                    "file": "/home/luc/Projects/Test/buildroot/support/docker/Dockerfile",
                    "level": "info"
                  }]
            ]])
            local diagnostic = parser({ output = output })
            assert.same({
                {
                    row = 24,
                    col = 1,
                    severity = 3,
                    code = "DL3059",
                    message = "Multiple consecutive `RUN` instructions. Consider consolidation.",
                },
            }, diagnostic)
        end)
    end)

    describe("flake8", function()
        local linter = diagnostics.flake8
        local parser = linter._opts.on_output
        local file = {
            [[#===- run-clang-tidy.py - Parallel clang-tidy runner ---------*- python -*--===#]],
        }

        it("should create a diagnostic", function()
            local output = [[run-clang-tidy.py:3:1: E265 block comment should start with '# ']]
            local diagnostic = parser(output, { content = file })
            assert.same({
                row = "3",
                col = "1",
                severity = 1,
                code = "E265",
                message = "block comment should start with '# '",
            }, diagnostic)
        end)
    end)

    describe("pylama", function()
        local linter = diagnostics.pylama
        local parser = linter._opts.on_output
        local exit_func = linter._opts.check_exit_code

        it("should create a diagnostic with error severity", function()
            local output = vim.json.decode([[
                  [{
                    "lnum": 3,
                    "col": 1,
                    "etype": "E",
                    "message": "block comment should start with '# '",
                    "number": "E265",
                    "source": "run-clang-tidy.py"
                  }]
            ]])
            local diagnostic = parser({ output = output })
            assert.same({
                {
                    row = 3,
                    col = 1,
                    severity = 1,
                    code = "E265",
                    message = "block comment should start with '# '",
                    source = "run-clang-tidy.py",
                },
            }, diagnostic)
        end)
        it("should count exit code of 1 as success", function()
            assert.is.True(exit_func(1))
            assert.is.True(exit_func(0))
            assert.is.False(exit_func(255))
        end)
    end)

    describe("misspell", function()
        local linter = diagnostics.misspell
        local parser = linter._opts.on_output
        local file = {
            [[Did I misspell langauge ?]],
        }

        it("should create a diagnostic", function()
            local output = [[stdin:1:15: "langauge" is a misspelling of "language"]]
            local diagnostic = parser(output, { content = file })
            assert.same({
                row = "1",
                col = 16,
                severity = 3,
                message = [["langauge" is a misspelling of "language"]],
            }, diagnostic)
        end)
    end)

    describe("vint", function()
        local linter = diagnostics.vint
        local parser = linter._opts.on_output

        it("should create a diagnostic with warning severity", function()
            local output = vim.json.decode([[
                  [{
                    "file_path": "/home/luc/Projects/Test/vim-scriptease/plugin/scriptease.vim",
                    "line_number": 5,
                    "column_number": 37,
                    "severity": "style_problem",
                    "description": "Use the full option name `compatible` instead of `cp`",
                    "policy_name": "ProhibitAbbreviationOption",
                    "reference": ":help option-summary"
                  }]
            ]])
            local diagnostic = parser({ output = output })
            assert.same({
                {
                    row = 5,
                    col = 37,
                    severity = 3,
                    code = "ProhibitAbbreviationOption",
                    message = "Use the full option name `compatible` instead of `cp`",
                },
            }, diagnostic)
        end)
    end)

    describe("yamllint", function()
        local linter = diagnostics.yamllint
        local parser = linter._opts.on_output
        local file = {
            [[true]],
        }

        it("should create a diagnostic with warning severity", function()
            local output = [[stdin:1:1: [warning] missing document start "---" (document-start)]]
            local diagnostic = parser(output, { content = file })
            assert.same({
                row = "1",
                col = "1",
                severity = 2,
                code = "document-start",
                message = 'missing document start "---"',
            }, diagnostic)
        end)
    end)

    describe("jsonlint", function()
        local linter = diagnostics.jsonlint
        local parser = linter._opts.on_output
        local file = {
            [[{ "name"* "foo" }]],
        }

        it("should create a diagnostic", function()
            local output = [[rules.json: line 1, col 8, found: 'INVALID' - expected: 'EOF', '}', ':', ',', ']'.]]
            local diagnostic = parser(output, { content = file })
            assert.same({
                row = "1",
                col = "8",
                message = "found: 'INVALID' - expected: 'EOF', '}', ':', ',', ']'.",
            }, diagnostic)
        end)
    end)

    describe("cue_fmt", function()
        local linter = diagnostics.cue_fmt
        local parser = linter._opts.on_output
        local cue_fmt_diagnostics
        local done = function(_diagnostics)
            cue_fmt_diagnostics = _diagnostics
        end

        it("should create a diagnostic", function()
            local output = vim.trim([[
            expected label or ':', found 'INT' 42:
                ../../../../../../../tmp/null-ls_GLJOFJ.cue:3:2
            ]])
            parser({ output = output }, done)
            assert.same({
                {
                    row = "3",
                    col = "2",
                    end_col = 3,
                    severity = 1,
                    message = "expected label or ':', found 'INT' 42:",
                    source = "cue_fmt",
                },
            }, cue_fmt_diagnostics)
        end)
    end)

    describe("alex", function()
        local linter = diagnostics.alex
        local parser = linter._opts.on_output
        local file = {
            [[ This is banging ]],
        }

        it("should create a diagnostic", function()
            local output =
                [[  1:9-1:16  warning  Reconsider using `banging`, it may be profane  banging  retext-profanities]]
            local diagnostic = parser(output, { content = file })
            assert.same({
                row = "1",
                col = "9",
                end_row = "1",
                end_col = "16",
                severity = 2,
                message = "Reconsider using `banging`, it may be profane ",
                code = "retext-profanities",
            }, diagnostic)
        end)
    end)

    describe("protolint", function()
        local linter = diagnostics.protolint
        local parser = linter._opts.on_output
        local protolint_diagnostics
        local done = function(_diagnostics)
            protolint_diagnostics = _diagnostics
        end
        after_each(function()
            protolint_diagnostics = nil
        end)

        it("should create a diagnostic with warning severity", function()
            local output = [[
            {
              "lints": [
                {
                  "filename": "sletmig.proto",
                  "line": 9,
                  "column": 1,
                  "message": "Found an incorrect indentation style \"\". \"  \" is correct.",
                  "rule": "INDENT"
                }
              ]
            } ]]
            parser({ output = output }, done)
            assert.same({
                {
                    row = 9,
                    col = 1,
                    severity = 2,
                    code = "INDENT",
                    message = 'Found an incorrect indentation style "". "  " is correct.',
                    source = "protolint",
                },
            }, protolint_diagnostics)
        end)
        it("should create a diagnostic with error severity", function()
            local output = [[found "pc" but expected [;]. Use -v for more details]]
            parser({ output = output }, done)
            assert.same({
                {
                    row = 1,
                    severity = 1,
                    message = 'found "pc" but expected [;]. Use -v for more details',
                    source = "protolint",
                },
            }, protolint_diagnostics)
        end)
    end)

    describe("protoc-gen-lint", function()
        local linter = diagnostics.protoc_gen_lint
        local parser = linter._opts.on_output

        it("should create a diagnostic with error severity", function()
            local file = [[
                syntax = "proto3";

                package sample;

                service Samle {
                // Faulty rpc
                rpc () returns () {}
                }
            ]]

            local output = [[sample.proto:6:7: Expected method name.]]
            local diagnostic = parser(output, { content = file })

            assert.same({
                row = "6",
                col = "7",
                message = "Expected method name.",
            }, diagnostic)
        end)
        it("should create a generic diagnostic with error severity", function()
            local file = [[
                yntax = "proto3"; // Faulty syntax definition
            ]]

            local output =
                [[[libprotobuf WARNING google/protobuf/compiler/parser.cc:562] No syntax specified for the proto file: null-ls_1UTH9g.proto. Please use 'syntax = "proto2";' or 'syntax = "proto3";' to specify a syntax version. (Defaulted to proto2 syntax.)]]
            local diagnostic = parser(output, { content = file })

            assert.same({
                message = "No syntax specified for the proto file: null-ls_1UTH9g.proto. Please use 'syntax = \"proto2\";' or 'syntax = \"proto3\";' to specify a syntax version. (Defaulted to proto2 syntax.)",
            }, diagnostic)
        end)
    end)

    describe("ansiblelint", function()
        local linter = diagnostics.ansiblelint
        local parser = linter._opts.on_output
        local file = {
            [[---]],
            [[- name: null-ls]],
            [[  hosts: all]],
            [[  tasks:]],
            [[    - name: This tasks is no good]],
            [[      assemble:]],
            [[        src: "files"]],
            [[        dest: "dest"]],
            [[      become: false]],
        }

        it("should create a diagnostic", function()
            local output = [[
                [
                  {
                    "type": "issue",
                    "check_name": "[risky-file-permissions] File permissions unset or incorrect",
                    "categories": [
                      "unpredictability",
                      "experimental"
                    ],
                    "severity": "blocker",
                    "description": "Missing or unsupported mode parameter can cause unexpected file permissions based on version of Ansible being used. Be explicit, like ``mode: 0644`` to avoid hitting this rule. Special ``preserve`` value is accepted only by copy, template modules. See https://github.com/ansible/ansible/issues/71200",
                    "fingerprint": "b66d9f9db860c0fedb7d1d583c5a808df9a1ed72b8abdbedeff0aad836490951",
                    "location": {
                      "path": "playbooks/test-ansible.yaml",
                      "lines": {
                        "begin": 5
                      }
                    },
                    "content": {
                      "body": "Task/Handler: This tasks is no good"
                    }
                  }
                ]
            ]]
            local diagnostic = parser({ output = vim.json.decode(output), content = file })
            assert.same({
                {
                    row = 5,
                    severity = 1,
                    message = "[risky-file-permissions] File permissions unset or incorrect",
                    filename = "playbooks/test-ansible.yaml",
                },
            }, diagnostic)
        end)
    end)

    describe("hamllint", function()
        local linter = diagnostics.haml_lint
        local parser = linter._opts.on_output

        it("should create a diagnostic with warning severity", function()
            local output = vim.json.decode([[
                {
                    "files": [
                        {
                            "path": "app/vies/test.html.haml",
                            "offenses": [
                                {
                                    "severity": "warning",
                                    "message": "Line is too long. [102/80]",
                                    "location": {
                                        "line": 7
                                    },
                                    "linter_name": "LineLength"
                                }
                            ]
                        }
                    ]
                }
            ]])

            local diagnostic = parser({ output = output })
            assert.same({
                {
                    row = 7,
                    severity = 2,
                    code = "LineLength",
                    message = "Line is too long. [102/80]",
                },
            }, diagnostic)
        end)
    end)

    describe("erblint", function()
        local linter = diagnostics.erb_lint
        local parser = linter._opts.on_output

        it("should create a diagnostic with warning severity", function()
            local output = vim.json.decode([[
                {
                    "files": [
                        {
                            "path": "test.html.erb",
                            "offenses": [
                                {
                                    "linter": "SpaceInHtmlTag",
                                    "message": "Extra space detected where there should be no space.",
                                    "location": {
                                        "start_line": 1,
                                        "start_column": 4,
                                        "last_line": 1,
                                        "last_column": 7,
                                        "length": 3
                                    }
                                }
                            ]
                        }
                    ]
                }
            ]])

            local diagnostic = parser({ output = output })
            assert.same({
                {
                    row = 1,
                    end_row = 1,
                    col = 4,
                    end_col = 8,
                    code = "SpaceInHtmlTag",
                    message = "Extra space detected where there should be no space.",
                },
            }, diagnostic)
        end)
    end)
end)
