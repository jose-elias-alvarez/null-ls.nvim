local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local api = vim.api

local M = {}

M.toggle_line_comment = {
    method = methods.internal.CODE_ACTION,
    name = "toggle_line_comment",
    filetypes = {},
    generator = {
        fn = function(params)
            local bufnr = api.nvim_get_current_buf()
            local commentstring = api.nvim_buf_get_option(bufnr, "commentstring")
            local raw_commentstring = commentstring:gsub(vim.pesc("%s"), "")
            local line = params.content[params.row]

            if line:find(raw_commentstring, nil, true) then
                local uncommented = line:gsub(vim.pesc(raw_commentstring), "")
                return {
                    {
                        title = "Uncomment line",
                        action = function()
                            api.nvim_buf_set_lines(bufnr, params.row - 1, params.row, false, {
                                uncommented,
                            })
                        end,
                    },
                }
            end

            return {
                {
                    title = "Comment line",
                    action = function()
                        api.nvim_buf_set_lines(bufnr, params.row - 1, params.row, false, {
                            string.format(commentstring, line),
                        })
                    end,
                },
            }
        end,
    },
}

M.mock_code_action = {
    method = methods.internal.CODE_ACTION,
    generator = {
        fn = function()
            return {
                {
                    title = "Mock action",
                    action = function()
                        print("I am a mock action!")
                    end,
                },
            }
        end,
    },
    filetypes = { "lua" },
}

M.slow_code_action = h.make_builtin({
    method = methods.internal.CODE_ACTION,
    filetypes = { "lua" },
    generator_opts = {
        command = "bash",
        args = { "./test/scripts/sleep-and-echo.sh" },
        timeout = 100,
        on_output = function(params, done)
            if not params.output then
                return done()
            end

            return done({
                {
                    title = "Slow mock action",
                    action = function()
                        print("I took too long!")
                    end,
                },
            })
        end,
    },
    factory = h.generator_factory,
})

M.cached_code_action = h.make_builtin({
    method = methods.internal.CODE_ACTION,
    filetypes = { "text" },
    generator_opts = {
        command = "ls",
        on_output = function(params, done)
            return done({
                {
                    title = params._null_ls_cached and "Cached" or "Not cached",
                    action = function() end,
                },
            })
        end,
        use_cache = true,
    },
    factory = h.generator_factory,
})

M.first_formatter = {
    method = methods.internal.FORMATTING,
    generator = {
        fn = function(_, done)
            return done({ { text = "first" } })
        end,
        async = true,
    },
    filetypes = { "text" },
}

M.second_formatter = {
    method = methods.internal.FORMATTING,
    generator = {
        fn = function(params, done)
            return done({ { text = params.content[1] == "first" and "sequential" or "second" } })
        end,
        async = true,
    },
    filetypes = { "text" },
}

M.runtime_skipped_formatter = {
    method = methods.internal.FORMATTING,
    generator = {
        fn = function(_, done)
            return done({ { text = "runtime" } })
        end,
        opts = {
            runtime_condition = function(_)
                return false
            end,
        },
        async = true,
    },
    filetypes = { "text" },
}

M.mock_hover = {
    method = methods.internal.HOVER,
    generator = {
        fn = function()
            return { "test" }
        end,
    },
    filetypes = { "text" },
}

return M
