local a = require("plenary.async_lib")

local c = require("null-ls.config")
local u = require("null-ls.utils")

local M = {}

M.run = a.async(function(params, postprocess)
    local generators = c.generators(params.method)
    if not generators then
        return {}
    end

    local futures, all_results = {}, {}
    for _, generator in ipairs(generators) do
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
                                postprocess(result)
                            end

                            table.insert(all_results, result)
                        end
                    end
                end)
            )
        end
    end

    a.await_all(futures)
    return all_results
end)

return M
