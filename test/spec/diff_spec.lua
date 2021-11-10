local diff = require("null-ls.diff")

describe("diff", function()
    -- TODO: add more tests
    describe("compute_diff", function()
        it("should compute diff", function()
            local start_lines = { "line1", "line2" }
            local end_lines = { "line1", "line3" }

            local diffed = diff.compute_diff(start_lines, end_lines)

            assert.equals(diffed.newText, "3")
            assert.equals(diffed.rangeLength, 1)
            assert.same(diffed.range, { start = { character = 4, line = 1 }, ["end"] = { character = 5, line = 1 } })
        end)

        it("should return empty diff when lines are the same", function()
            local start_lines = { "line1", "line2" }
            local end_lines = { "line1", "line2" }

            local diffed = diff.compute_diff(start_lines, end_lines)

            assert.equals(diffed.newText, "")
            assert.equals(diffed.rangeLength, 0)
        end)
    end)
end)
