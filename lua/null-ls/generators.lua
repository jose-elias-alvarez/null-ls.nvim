local a = require("plenary.async_lib")

local c = require("null-ls.config")
local u = require("null-ls.utils")

local M = {}

M.run = function(generators, params, postprocess, callback)
    local runner = a.async(function()
        u.debug_log("running generators for method " .. params.method)

        if vim.tbl_isempty(generators) then
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
                        generator._failed = true
                        return
                    end

                    if not results then
                        return
                    end

                    for _, result in ipairs(results) do
                        if postprocess then
                            postprocess(result, params, generator)
                        end

                        table.insert(all_results, result)
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

M.run_sequentially = function(generators, make_params, postprocess, callback)
    local generator_index, wrapped_callback = 1, nil
    local run_next = function()
        local next_generator = generators[generator_index]
        if not next_generator then
            return
        end
        -- schedule to make sure params reflect current buffer state
        vim.schedule(function()
            M.run({ next_generator }, make_params(), postprocess, wrapped_callback)
        end)
    end

    wrapped_callback = function(...)
        callback(...)
        generator_index = generator_index + 1
        run_next()
    end

    run_next()
end

M.run_registered = function(opts)
    local filetype, method, params, postprocess, callback =
        opts.filetype, opts.method, opts.params, opts.postprocess, opts.callback
    local generators = M.get_available(filetype, method)

    M.run(generators, params, postprocess, callback)
end

M.run_registered_sequentially = function(opts)
    local filetype, method, make_params, postprocess, callback =
        opts.filetype, opts.method, opts.make_params, opts.postprocess, opts.callback
    local generators = M.get_available(filetype, method)

    M.run_sequentially(generators, make_params, postprocess, callback)
end

M.get_available = function(filetype, method)
    return vim.tbl_filter(function(generator)
        return not generator._failed and u.filetype_matches(generator.filetypes, filetype)
    end, c.get()._generators[method] or {})
end

M.can_run = function(filetype, method)
    return not vim.tbl_isempty(M.get_available(filetype, method))
end

return M
