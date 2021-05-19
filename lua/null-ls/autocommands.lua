local api = vim.api

local M = {}

local create_augroup = function(name, trigger, fn, ft)
    api.nvim_exec(string.format([[
    augroup %s
        autocmd!
        autocmd %s %s lua require'null-ls'.%s
    augroup END
    ]], name, trigger, ft or "*", fn), false)
end

M.setup =
    function() create_augroup("NullLsAttach", "BufEnter", "try_attach()") end

return M
