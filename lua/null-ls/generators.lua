local c = require("null-ls.config")
local u = require("null-ls.utils")

local M = {}

M.run = function(generators, params, postprocess, callback)
    -- NOTE: avoid importing plenary elsewhere to limit server dependencies
    local a = require("plenary.async_lib")

    local runner = a.async(function()
        u.debug_log("running generators for method " .. params.method)

        if not generators then
            u.debug_log("no generators registered")
            return {}
        end

        local futures, all_results = {}, {}
        for index, generator in ipairs(generators) do
            if u.filetype_matches(generator.filetypes, params.ft) then
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
                                    postprocess(result, params, index)
                                end

                                table.insert(all_results, result)
                            end
                        end
                    end)
                )

                table.insert(params.generators, generator)
            end
        end

        a.await_all(futures)
        return all_results
    end)

    a.run(runner(), function(results)
        callback(results, params)
    end)
end

M.run_registered = function(params, postprocess, callback)
    local generators = c.generators(params.method)
    M.run(generators, params, postprocess, callback)
end

M.can_run = function(filetype, method)
    local generators = c.generators(method)
    if not generators then
        return false
    end
    for _, generator in ipairs(generators) do
        if u.filetype_matches(generator.filetypes, filetype) then
            return true
        end
    end
    return false
end

return M
