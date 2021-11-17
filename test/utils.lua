local M = {}

M.test_dir = vim.fn.getcwd() .. "/test"

M.test_file_path = function(file)
    return M.test_dir .. "/files/" .. file
end
M.edit_test_file = function(file)
    vim.cmd("e! " .. M.test_file_path(file))
end

M.wipeout = function()
    vim.cmd("bufdo! bwipeout!")
end

return M
