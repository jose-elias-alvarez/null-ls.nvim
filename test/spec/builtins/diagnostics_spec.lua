local mock = require("luassert.mock")

local diagnostics = require("null-ls.builtins").diagnostics
mock(require("null-ls.logger"), true)

describe("diagnostics", function()
    describe("spectral", function()
        local linter = diagnostics.spectral
        local parser = linter._opts.on_output

        it("should create a diagnostic with an Warning severity", function()
            local output = vim.json.decode([[
                [
                    {
                        "code": "oas3-operation-security-defined",
                        "path": [
                                "security",
                                "0",
                                "bearer"
                        ],
                        "message": "API \"security\" values must match a scheme defined in the \"components.securitySchemes\" object.",
                        "severity": 1,
                        "range": {
                                "start": {
                                        "line": 659,
                                        "character": 11
                                },
                                "end": {
                                        "line": 659,
                                        "character": 14
                                }
                        },
                        "source": "/home/luizcorreia/repos/smiles/OpenApi/openapi.yaml"
                    }
                ]
            ]])

            local diagnostic = parser({ output = output })
            assert.same({
                {
                    code = "oas3-operation-security-defined",
                    col = 11,
                    end_col = 14,
                    end_row = 660,
                    message = 'API "security" values must match a scheme defined in the "components.securitySchemes" object.',
                    path = { "security", "0", "bearer" },
                    row = 660,
                    severity = 2,
                    source = "Spectral",
                },
            }, diagnostic)
        end)
    end)
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

    describe("mypy", function()
        local linter = diagnostics.mypy
        local parser = linter._opts.on_output
        it("should handle full diagnostic", function()
            local output =
                'test.py:1:1: error: Library stubs not installed for "requests" (or incompatible with Python 3.9)  [import]'
            local diagnostic = parser(output, {})
            assert.same({
                row = "1",
                col = "1",
                severity = 1,
                message = 'Library stubs not installed for "requests" (or incompatible with Python 3.9)',
                filename = "test.py",
                code = "import",
            }, diagnostic)
        end)

        it("should diagnostic without code", function()
            local output = 'test.py:1:1: note: Hint: "python3 -m pip install types-requests"'
            local diagnostic = parser(output, {})
            assert.same({
                row = "1",
                col = "1",
                severity = 3,
                message = 'Hint: "python3 -m pip install types-requests"',
                filename = "test.py",
            }, diagnostic)
        end)

        it("should handle diagnostic with no column or error code", function()
            local output = [[tests/slack_app/conftest.py:10: error: Unused "type: ignore" comment]]
            local diagnostic = parser(output, {})
            assert.same({
                row = "10",
                severity = 1,
                message = 'Unused "type: ignore" comment',
                filename = "tests/slack_app/conftest.py",
            }, diagnostic)
        end)
    end)

    describe("opacheck", function()
        local linter = diagnostics.opacheck
        local parser = linter._opts.on_output

        it("should create a diagnostic with error severity", function()
            local output = vim.json.decode([[
            {
              "errors": [
                {
                  "message": "var tenant_id is unsafe",
                  "code": "rego_unsafe_var_error",
                  "location": {
                    "file": "src/geo.rego",
                    "row": 49,
                    "col": 3
                  }
                }
              ]
            } ]])
            local diagnostic = parser({ output = output })
            assert.same({
                {
                    row = 49,
                    col = 3,
                    severity = 1,
                    message = "var tenant_id is unsafe",
                    filename = "src/geo.rego",
                    source = "opacheck",
                    code = "rego_unsafe_var_error",
                },
            }, diagnostic)
        end)

        it("should not create a diagnostic without location", function()
            local output = vim.json.decode([[
            {
              "errors": [
                {
                  "message": "var tenant_id is unsafe",
                  "code": "rego_unsafe_var_error"
                }
              ]
            } ]])
            local diagnostic = parser({ output = output })
            assert.same({}, diagnostic)
        end)
    end)
    describe("glslc", function()
        local linter = diagnostics.glslc
        local parser = linter._opts.on_output

        -- some of the example output gotten from: https://github.com/google/shaderc/blob/main/glslc/test/messages_tests.py
        it("glslc error", function()
            local output =
                [[glslc: error: 'path/to/tempfile.glsl': .glsl file encountered but no -fshader-stage specified ahead]]
            local diagnostic = parser(output, {})
            assert.same({
                severity = 1,
                message = ".glsl file encountered but no -fshader-stage specified ahead",
            }, diagnostic)
        end)
        it("line error with quotes", function()
            local output =
                [[filename.glsl:14: error: 'non-opaque uniforms outside a block' : not allowed when using GLSL for Vulkan]]
            local diagnostic = parser(output, {})
            assert.same({
                filename = "filename.glsl",
                row = "14",
                severity = 1,
                message = "'non-opaque uniforms outside a block' : not allowed when using GLSL for Vulkan",
            }, diagnostic)
        end)
        it("line error with empty quotes", function()
            local output = [[filename2.glsl:2: error: '' : function does not return a value: main]]
            local diagnostic = parser(output, {})
            assert.same({
                filename = "filename2.glsl",
                row = "2",
                severity = 1,
                message = "'' : function does not return a value: main",
            }, diagnostic)
        end)
        it("line warning without quotes", function()
            local output =
                [[filename3.glsl:2: warning: attribute deprecated in version 130; may be removed in future release]]
            local diagnostic = parser(output, {})
            assert.same({
                filename = "filename3.glsl",
                row = "2",
                severity = 2,
                message = "attribute deprecated in version 130; may be removed in future release",
            }, diagnostic)
        end)
        it("file warning", function()
            local output =
                [[filename4.glsl: warning: (version, profile) forced to be (400, none), while in source code it is (550, none)]]
            local diagnostic = parser(output, {})
            assert.same({
                filename = "filename4.glsl",
                severity = 2,
                message = "(version, profile) forced to be (400, none), while in source code it is (550, none)",
            }, diagnostic)
        end)
    end)

    describe("checkstyle", function()
        local linter = diagnostics.checkstyle
        local parser = linter._opts.on_output

        it("should parse the usual output", function()
            local output = vim.json.decode([[
                {
                  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
                  "version": "2.1.0",
                  "runs": [
                    {
                      "tool": {
                        "driver": {
                          "downloadUri": "https://github.com/checkstyle/checkstyle/releases/",
                          "fullName": "Checkstyle",
                          "informationUri": "https://checkstyle.org/",
                          "language": "en",
                          "name": "Checkstyle",
                          "organization": "Checkstyle",
                          "rules": [
                          ],
                          "semanticVersion": "10.3.4",
                          "version": "10.3.4"
                        }
                      },
                      "results": [
                        {
                          "level": "warning",
                          "locations": [
                            {
                              "physicalLocation": {
                                "artifactLocation": {
                                  "uri": "/home/someuser/Code/someproject/FooController.java"
                                },
                                "region": {
                                  "startColumn": 1,
                                  "startLine": 1
                                }
                              }
                            }
                          ],
                          "message": {
                            "text": "Missing a Javadoc comment."
                          },
                          "ruleId": "javadoc.missing"
                        },
                        {
                          "level": "warning",
                          "locations": [
                            {
                              "physicalLocation": {
                                "artifactLocation": {
                                  "uri": "/home/someuser/Code/someproject/ReportController.java"
                                },
                                "region": {
                                  "startColumn": 4,
                                  "startLine": 74
                                }
                              }
                            }
                          ],
                          "message": {
                            "text": "Missing a Javadoc comment (Test)."
                          },
                          "ruleId": "javadoc.missing.test"
                        }
                      ]
                    }
                  ]
                }
            ]])
            local parsed = parser({ output = output })
            assert.same({
                {
                    row = 1,
                    col = 1,
                    end_col = 2,
                    code = "javadoc.missing",
                    message = "Missing a Javadoc comment.",
                    severity = vim.diagnostic.severity.WARN,
                    filename = "/home/someuser/Code/someproject/FooController.java",
                },
                {
                    row = 74,
                    col = 4,
                    end_col = 5,
                    code = "javadoc.missing.test",
                    message = "Missing a Javadoc comment (Test).",
                    severity = vim.diagnostic.severity.WARN,
                    filename = "/home/someuser/Code/someproject/ReportController.java",
                },
            }, parsed)
        end)

        it('should ignore the "ends with n errors" message', function()
            local output = vim.json.decode([[
                {
                  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
                  "version": "2.1.0",
                  "runs": [
                    {
                      "tool": {
                        "driver": {
                          "downloadUri": "https://github.com/checkstyle/checkstyle/releases/",
                          "fullName": "Checkstyle",
                          "informationUri": "https://checkstyle.org/",
                          "language": "en",
                          "name": "Checkstyle",
                          "organization": "Checkstyle",
                          "rules": [
                          ],
                          "semanticVersion": "10.3.4",
                          "version": "10.3.4"
                        }
                      },
                      "results": [
                        {
                          "level": "warning",
                          "locations": [
                            {
                              "physicalLocation": {
                                "artifactLocation": {
                                  "uri": "/home/someuser/Code/someproject/FooController.java"
                                },
                                "region": {
                                  "startColumn": 1,
                                  "startLine": 1
                                }
                              }
                            }
                          ],
                          "message": {
                            "text": "Missing a Javadoc comment."
                          },
                          "ruleId": "javadoc.missing"
                        }
                      ]
                    }
                  ]
                }
            ]])
            local err = [[Checkstyle ends with 42 errors.\n]]
            local parsed = parser({ output = output, err = err })
            assert.same({
                {
                    row = 1,
                    col = 1,
                    end_col = 2,
                    code = "javadoc.missing",
                    message = "Missing a Javadoc comment.",
                    severity = vim.diagnostic.severity.WARN,
                    filename = "/home/someuser/Code/someproject/FooController.java",
                },
            }, parsed)
        end)

        it("should rephrase the missing config message", function()
            local parsed = parser({ bufnr = 42, output = nil, err = [[Must specify a config XML file.\n]] })
            assert.same({
                {
                    message = "You need to specify a configuration for checkstyle. See"
                        .. " https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#checkstyle",
                    severity = vim.diagnostic.severity.ERROR,
                    bufnr = 42,
                },
            }, parsed)
        end)

        it("should add other errors", function()
            local output = vim.json.decode([[
                {
                  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
                  "version": "2.1.0",
                  "runs": [
                    {
                      "tool": {
                        "driver": {
                          "downloadUri": "https://github.com/checkstyle/checkstyle/releases/",
                          "fullName": "Checkstyle",
                          "informationUri": "https://checkstyle.org/",
                          "language": "en",
                          "name": "Checkstyle",
                          "organization": "Checkstyle",
                          "rules": [
                          ],
                          "semanticVersion": "10.3.4",
                          "version": "10.3.4"
                        }
                      },
                      "results": [
                        {
                          "level": "warning",
                          "locations": [
                            {
                              "physicalLocation": {
                                "artifactLocation": {
                                  "uri": "/home/someuser/Code/someproject/FooController.java"
                                },
                                "region": {
                                  "startColumn": 1,
                                  "startLine": 1
                                }
                              }
                            }
                          ],
                          "message": {
                            "text": "Missing a Javadoc comment."
                          },
                          "ruleId": "javadoc.missing"
                        }
                      ]
                    }
                  ]
                }
            ]])
            local err = [[Some other error.\n]]
            local parsed = parser({ bufnr = 42, output = output, err = err })
            assert.same({
                {
                    message = vim.trim(err),
                    severity = vim.diagnostic.severity.ERROR,
                    bufnr = 42,
                },
                {
                    row = 1,
                    col = 1,
                    end_col = 2,
                    code = "javadoc.missing",
                    message = "Missing a Javadoc comment.",
                    severity = vim.diagnostic.severity.WARN,
                    filename = "/home/someuser/Code/someproject/FooController.java",
                },
            }, parsed)
        end)
    end)

    describe("pmd", function()
        local linter = diagnostics.pmd
        local parser = linter._opts.on_output

        it("should parse the usual output", function()
            local output = vim.json.decode([[
                {
                  "formatVersion": 0,
                  "pmdVersion": "6.50.0",
                  "timestamp": "2022-10-21T20:44:51.872+02:00",
                  "files": [
                    {
                      "filename": "/home/someuser/Code/someproject/FooController.java",
                      "violations": [
                        {
                          "beginline": 1,
                          "begincolumn": 8,
                          "endline": 2,
                          "endcolumn": 1,
                          "description": "Class comments are required",
                          "rule": "CommentRequired",
                          "ruleset": "Documentation",
                          "priority": 3,
                          "externalInfoUrl": "https://pmd.github.io/pmd-6.50.0/pmd_rules_java_documentation.html#commentrequired"
                        }
                      ]
                    },
                    {
                      "filename": "/home/someuser/Code/someproject/ReportController.java",
                      "violations": [
                        {
                          "beginline": 76,
                          "begincolumn": 8,
                          "endline": 712,
                          "endcolumn": 1,
                          "description": "Class comments are required 2",
                          "rule": "CommentRequired2",
                          "ruleset": "Documentation",
                          "priority": 3,
                          "externalInfoUrl": "https://pmd.github.io/pmd-6.50.0/pmd_rules_java_documentation.html#commentrequired"
                        },
                        {
                          "beginline": 77,
                          "begincolumn": 23,
                          "endline": 77,
                          "endcolumn": 57,
                          "description": "Field comments are required 3",
                          "rule": "CommentRequired3",
                          "ruleset": "Documentation",
                          "priority": 3,
                          "externalInfoUrl": "https://pmd.github.io/pmd-6.50.0/pmd_rules_java_documentation.html#commentrequired"
                        }
                      ]
                    }
                  ],
                  "suppressedViolations": [],
                  "processingErrors": [],
                  "configurationErrors": []
                }
            ]])
            local parsed = parser({ output = output })
            assert.same({
                {
                    row = 1,
                    col = 8,
                    end_row = 2,
                    end_col = 2,
                    code = "Documentation/CommentRequired",
                    message = "Class comments are required",
                    severity = vim.diagnostic.severity.WARN,
                    filename = "/home/someuser/Code/someproject/FooController.java",
                },
                {
                    row = 76,
                    col = 8,
                    end_row = 712,
                    end_col = 2,
                    code = "Documentation/CommentRequired2",
                    message = "Class comments are required 2",
                    severity = vim.diagnostic.severity.WARN,
                    filename = "/home/someuser/Code/someproject/ReportController.java",
                },
                {
                    row = 77,
                    col = 23,
                    end_row = 77,
                    end_col = 58,
                    code = "Documentation/CommentRequired3",
                    message = "Field comments are required 3",
                    severity = vim.diagnostic.severity.WARN,
                    filename = "/home/someuser/Code/someproject/ReportController.java",
                },
            }, parsed)
        end)

        it("should show stderr errors as errors", function()
            local output = vim.json.decode([[
                {
                  "formatVersion": 0,
                  "pmdVersion": "6.50.0",
                  "timestamp": "2022-10-21T20:44:51.872+02:00",
                  "files": [],
                  "suppressedViolations": [],
                  "processingErrors": [],
                  "configurationErrors": []
                }
            ]])
            local err = [[Oct 21, 2022 10:57:30 PM net.sourceforge.pmd.PMD someCode
ERROR: Some error text.    ]]
            local parsed = parser({ bufnr = 42, err = err, output = output })
            assert.same({
                {
                    code = "stderr",
                    message = "Some error text.",
                    severity = vim.diagnostic.severity.ERROR,
                    bufnr = 42,
                },
            }, parsed)
        end)

        it("should show stderr warnings as warnings", function()
            local output = vim.json.decode([[
                {
                  "formatVersion": 0,
                  "pmdVersion": "6.50.0",
                  "timestamp": "2022-10-21T20:44:51.872+02:00",
                  "files": [],
                  "suppressedViolations": [],
                  "processingErrors": [],
                  "configurationErrors": []
                }
            ]])
            local err = [[Oct 21, 2022 10:57:30 PM net.sourceforge.pmd.PMD someCode
WARNING: Some warning text.    ]]
            local parsed = parser({ bufnr = 42, err = err, output = output })
            assert.same({
                {
                    code = "stderr",
                    message = "Some warning text.",
                    severity = vim.diagnostic.severity.WARN,
                    bufnr = 42,
                },
            }, parsed)
        end)

        it("should show stderr infos as infos", function()
            local output = vim.json.decode([[
                {
                  "formatVersion": 0,
                  "pmdVersion": "6.50.0",
                  "timestamp": "2022-10-21T20:44:51.872+02:00",
                  "files": [],
                  "suppressedViolations": [],
                  "processingErrors": [],
                  "configurationErrors": []
                }
            ]])
            local err = [[Oct 21, 2022 10:57:30 PM net.sourceforge.pmd.PMD someCode
INFO: Some info text.    ]]
            local parsed = parser({ bufnr = 42, err = err, output = output })
            assert.same({
                {
                    code = "stderr",
                    message = "Some info text.",
                    severity = vim.diagnostic.severity.INFO,
                    bufnr = 42,
                },
            }, parsed)
        end)

        it("should rephrase the missing ruleset message", function()
            local parsed = parser({
                bufnr = 42,
                output = nil,
                err = [[The following option is required: --rulesets, -rulesets, -R
Run with --help for command line help.]],
            })
            assert.same({
                {
                    message = "You need to specify a ruleset for PMD. See"
                        .. " https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#pmd",
                    severity = vim.diagnostic.severity.ERROR,
                    bufnr = 42,
                },
            }, parsed)
        end)

        it("should ignore the analysis cache messages", function()
            local parsed = parser({
                bufnr = 42,
                output = nil,
                err = [[Oct 27, 2022 10:27:21 AM net.sourceforge.pmd.cache.FileAnalysisCache loadFromFile
INFO: Analysis cache loaded
Oct 27, 2022 10:27:21 AM net.sourceforge.pmd.cache.AbstractAnalysisCache checkValidity
INFO: Analysis cache invalidated, rulesets changed.
Oct 27, 2022 10:27:27 AM net.sourceforge.pmd.cache.FileAnalysisCache persist
INFO: Analysis cache updated]],
            })
            assert.same({}, parsed)
        end)
    end)

    describe("clazy", function()
        local linter = diagnostics.clazy
        local parser = linter._opts.on_output

        it("should create a diagnostic with warning severity", function()
            local output =
                "/home/null-ls/project/src/file.cpp:57:5: warning: signal selected is overloaded [-Wclazy-overloaded-signal]"
            local diagnostic = parser(output, {
                bufname = "/home/null-ls/project/src/file.cpp",
            })

            assert.same({
                row = "57",
                col = "5",
                source = "clazy",
                message = "signal selected is overloaded [-Wclazy-overloaded-signal]",
                severity = 2,
            }, diagnostic)
        end)
        it("should ignore line with diagnostic from other file", function()
            local output =
                "/home/null-ls/project/src/other_file.cpp:57:5: warning: signal selected is overloaded [-Wclazy-overloaded-signal]"
            local diagnostic = parser(output, {
                bufname = "/home/null-ls/project/src/file.cpp",
            })

            assert.same(nil, diagnostic)
        end)
        it("should ignore line with no diagnostic info", function()
            local output = "In file included from /home/null-ls/project/src/file.cpp:40:"
            local diagnostic = parser(output, {
                bufname = "/home/null-ls/project/src/file.cpp",
            })

            assert.same(nil, diagnostic)
        end)
    end)
end)
