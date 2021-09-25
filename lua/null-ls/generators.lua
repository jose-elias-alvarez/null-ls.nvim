local c = require("null-ls.config")
local u = require("null-ls.utils")

local M = {}

M.run = function(generators, params, postprocess, callback)
    local a = require("plenary.async")

    local runner = function()
        u.debug_log("running generators for method " .. params.method)

        if vim.tbl_isempty(generators) then
            u.debug_log("no generators available")
            return {}
        end

        local futures, all_results = {}, {}
        for _, generator in ipairs(generators) do
            table.insert(futures, function()
                local copied_params = vim.deepcopy(params)

                local runtime_condition = generator.opts and generator.opts.runtime_condition
                if runtime_condition and not runtime_condition(copied_params) then
                    return
                end

                local to_run = generator.async and a.wrap(generator.fn, 2) or generator.fn
                local ok, results = pcall(to_run, copied_params)
                a.util.scheduler()

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
                        postprocess(result, copied_params, generator)
                    end

                    table.insert(all_results, result)
                end
            end)
        end

        a.util.join(futures)
        return all_results
    end

    a.run(runner, function(results)
        callback(results, params)
    end)
end

M.run_sequentially = function(generators, make_params, postprocess, callback, after_all)
    local generator_index, wrapped_callback = 1, nil
    local run_next = function()
        local next_generator = generators[generator_index]
        if not next_generator then
            if after_all then
                after_all()
            end
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
    local filetype, method, make_params, postprocess, callback, after_all =
        opts.filetype, opts.method, opts.make_params, opts.postprocess, opts.callback, opts.after_all
    local generators = M.get_available(filetype, method)

    M.run_sequentially(generators, make_params, postprocess, callback, after_all)
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
