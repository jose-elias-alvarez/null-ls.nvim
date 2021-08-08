local a = require("plenary.async_lib")

local c = require("null-ls.config")
local u = require("null-ls.utils")

local M = {}

M.run = function(generators, params, postprocess, callback)
    local runner = a.async(function()
        u.debug_log("running generators for method " .. params.method)

        if not generators or vim.tbl_isempty(generators) then
            u.debug_log("no generators available")
            return {}
        end

        local futures, all_results = {}, {}
        for _, generator in ipairs(generators) do
            table.insert(
                futures,
                a.future(function()
                    local ok, results
                    if generator.async then
                        local wrapped = a.wrap(generator.fn, 2)
                        ok, results = a.await(a.util.protected(wrapped(params)))
                    else
                        ok, results = pcall(generator.fn, params)
                    end
                    a.await(a.scheduler())

                    if not ok then
                        u.echo("WarningMsg", "failed to run generator: " .. results)
                    elseif type(results) == "table" then
                        for _, result in ipairs(results) do
                            if postprocess then
                                postprocess(result, params, generator)
                            end

                            table.insert(all_results, result)
                        end
                    end
                end)
            )
        end

        a.await_all(futures)
        return all_results
    end)

    a.run(runner(), function(results)
        callback(results, params)
    end)
end

M.run_registered = function(opts)
    local filetype, method, params, postprocess, callback =
        opts.filetype, opts.method, opts.params, opts.postprocess, opts.callback
    local generators = M.get_available(filetype, method)

    M.run(generators, params, postprocess, callback)
end

M.get_available = function(filetype, method)
    return vim.tbl_filter(function(generator)
        return u.filetype_matches(generator.filetypes, filetype)
    end, c.get()._generators[method] or {})
end

M.can_run = function(filetype, method)
    return #M.get_available(filetype, method) > 0
end

return M
