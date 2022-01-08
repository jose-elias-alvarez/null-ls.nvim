local u = require("null-ls.utils")

local MOCK_SOURCE_WAIT_TIME = 50
local REAL_SOURCE_WAIT_TIME = 400

local M = {}

M.test_dir = u.path.join(vim.loop.cwd(), "test")

M.get_test_file_path = function(file)
    return u.path.join(M.test_dir, "files", file)
end
M.edit_test_file = function(file)
    vim.cmd("e! " .. M.get_test_file_path(file))
end

M.wait = function(time)
    -- 0 effectively waits for the scheduler
    vim.wait(time or 0)
end

M.wait_for_mock_source = function(count)
    count = count or 1
    M.wait(MOCK_SOURCE_WAIT_TIME * count)
end

M.wait_for_real_source = function(count)
    count = count or 1
    M.wait(REAL_SOURCE_WAIT_TIME * count)
end

M.wipeout = function()
    vim.cmd("bufdo! bwipeout!")
end

return M
