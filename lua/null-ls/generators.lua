local u = require("null-ls.utils")
local log = require("null-ls.logger")

local M = {}

M.run = function(generators, params, postprocess, callback, should_index)
    local a = require("plenary.async")

    local runner = function()
        log:trace("running generators for method " .. params.method)

        if vim.tbl_isempty(generators) then
            log:debug("no generators available")
            return {}
        end

        local futures, all_results = {}, {}
        local iterator = should_index and pairs or ipairs
        for index, generator in iterator(generators) do
            local to_insert = all_results
            if should_index then
                all_results[index] = {}
                to_insert = all_results[index]
            end

            table.insert(futures, function()
                local copied_params = vim.deepcopy(params)

                local runtime_condition = generator.opts and generator.opts.runtime_condition
                if runtime_condition and not runtime_condition(copied_params) then
                    return
                end

                local to_run = generator.async and a.wrap(generator.fn, 2) or generator.fn
                local protected_call = generator.async and a.util.apcall or pcall
                local ok, results = protected_call(to_run, copied_params)
                a.util.scheduler()

                -- allow generators to pass errors without throwing them (e.g. in luv callbacks)
                if results and results._generator_err then
                    ok = false
                    results = results._generator_err
                end

                if not ok then
                    log:warn("failed to run generator: " .. results)
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

                    table.insert(to_insert, result)
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
    local filetype, method, params, postprocess, callback, index_by_id =
        opts.filetype, opts.method, opts.params, opts.postprocess, opts.callback, opts.index_by_id
    local generators = M.get_available(filetype, method, index_by_id)

    M.run(generators, params, postprocess, callback, index_by_id)
end

M.run_registered_sequentially = function(opts)
    local filetype, method, make_params, postprocess, callback, after_all =
        opts.filetype, opts.method, opts.make_params, opts.postprocess, opts.callback, opts.after_all
    local generators = M.get_available(filetype, method)

    M.run_sequentially(generators, make_params, postprocess, callback, after_all)
end

M.get_available = function(filetype, method, index_by_id)
    local available = {}
    for _, source in ipairs(require("null-ls.sources").get_available(filetype, method)) do
        if index_by_id then
            available[source.id] = source.generator
        else
            table.insert(available, source.generator)
        end
    end
    return available
end

M.can_run = function(filetype, method)
    return #M.get_available(filetype, method) > 0
end

return M
