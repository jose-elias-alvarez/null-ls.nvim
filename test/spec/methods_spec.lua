local methods = require("null-ls.methods")

describe("methods", function()
    describe("exists", function()
        it("should return true if method exists", function()
            local exists = methods:exists(methods.CODE_ACTION)

            assert.equals(exists, true)
        end)

        it("should return false if method does not exist", function()
            local exists = methods:exists("someMethodThatWillNeverExist")

            assert.equals(exists, false)
        end)
    end)
end)
