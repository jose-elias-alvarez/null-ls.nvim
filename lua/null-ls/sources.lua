local a = require("plenary.async_lib")
local u = require("null-ls.utils")
local methods = require("null-ls.methods")

local validate = vim.validate

local _generators = {}

local M = {}

M.get_generators = function(method)
    return method and _generators[method] or _generators
end

M.register = function(sources, force)
    for _, source in ipairs(sources) do
        local method, generators, filetypes = source.method, source.generators,
                                              source.filetypes
        validate({
            method = {method, "string"},
            generators = {generators, "table"},
            filetypes = {filetypes, "table", true}
        })

        if not methods:exists(method) and not force then
            u.echo("WarningMsg", "method " .. method .. " is not supported")
        else
            if not _generators[method] then _generators[method] = {} end
            for _, generator in ipairs(generators) do
                if filetypes then generator.filetypes = filetypes end
                table.insert(_generators[method], generator)
            end
        end
    end
end

M.reset = function(method)
    if method then
        _generators[method] = {}
        return
    end

    _generators = {}
end

M.run_generators = a.async(function(params, postprocess)
    local generators = M.get_generators(params.method)
    if not generators then return {} end

    local futures, all_results = {}, {}
    for _, generator in ipairs(generators) do
        if u.filetype_matches(generator, params.ft) then
            table.insert(futures, a.future(
                             function()
                    local ok, results
                    if generator.async then
                        local wrapped = a.wrap(generator.fn, 2)
                        ok, results = a.await(a.util.protected(wrapped(params)))
                    else
                        ok, results = pcall(generator.fn, params)
                    end
                    a.await(a.scheduler())

                    if not ok then
                        u.echo("WarningMsg",
                               "failed to run generator: " .. results)
                    elseif type(results) == "table" then
                        for _, result in ipairs(results) do
                            if postprocess then
                                postprocess(result)
                            end

                            table.insert(all_results, result)
                        end
                    end
                end))
        end
    end

    a.await_all(futures)
    return all_results
end)

return M
