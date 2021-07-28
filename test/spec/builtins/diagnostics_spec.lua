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
end)
