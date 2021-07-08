local api = vim.api

local exec = function(...)
    api.nvim_exec(..., false)
end

local M = {}

local names = { GROUP = "NullLsAutocommands", REGISTERED = "NullLsRegistered" }
M.names = names

local register = function(trigger, fn, ft)
    if not vim.fn.exists("#" .. names.GROUP) then
        exec(string.format(
            [[
        augroup %s
            autocmd!
        augroup END
        ]],
            names.GROUP
        ))
    end

    exec(string.format(
        [[
    augroup %s
        autocmd %s %s lua require'null-ls'.%s
    augroup END
    ]],
        names.GROUP,
        trigger,
        ft or "*",
        fn
    ))
end

M.setup = function()
    register("BufEnter,FocusGained", "try_attach()")
    register("User", "attach_or_refresh()", names.REGISTERED)
end

M.reset = function()
    exec(string.format(
        [[
    augroup %s
        autocmd!
    augroup END
    ]],
        names.GROUP
    ))

    vim.cmd("augroup! " .. names.GROUP)
end

M.trigger = function(name)
    vim.cmd("doautocmd User " .. name)
end

return M
