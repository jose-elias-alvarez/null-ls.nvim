local M = {}

M.test_dir = vim.fn.getcwd() .. "/test"
M.edit_test_file = function(file)
    vim.cmd("e " .. M.test_dir .. "/files/" .. file)
end

return M
