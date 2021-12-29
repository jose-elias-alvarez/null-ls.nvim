local log = require("null-ls.logger")

local M = {}

M.run = function(generators, params, opts, callback)
    local a = require("plenary.async")

    local runner = function()
        log:trace("running generators for method " .. params.method)

        if vim.tbl_isempty(generators) then
            log:debug("no generators available")
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
                local protected_call = generator.async and a.util.apcall or pcall
                local ok, results = protected_call(to_run, copied_params)
                a.util.scheduler()

                if results then
                    -- allow generators to pass errors without throwing them (e.g. in luv callbacks)
                    if results._generator_err then
                        ok = false
                        results = results._generator_err
                    end

                    -- allow generators to deregister their parent sources
                    if results._should_deregister then
                        results = nil
                        vim.schedule(function()
                            require("null-ls.sources").deregister({ id = generator.source_id })
                        end)
                    end
                end

                -- TODO: pass generator error trace
                if not ok then
                    log:warn("failed to run generator: " .. results)
                    generator._failed = true
                    return
                end

                results = results or {}
                local postprocess, after_each = opts.postprocess, opts.after_each
                for _, result in ipairs(results) do
                    if postprocess then
                        postprocess(result, copied_params, generator)
                    end

                    table.insert(all_results, result)
                end

                if after_each then
                    after_each(results, copied_params, generator)
                end
            end)
        end

        a.util.join(futures)
        return all_results
    end

    a.run(runner, function(results)
        if callback then
            callback(results, params)
        end
    end)
end

M.run_sequentially = function(generators, make_params, opts, callback)
    local postprocess, after_each, after_all = opts.postprocess, opts.after_each, opts.after_all

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
            M.run(
                { next_generator },
                make_params(),
                { postprocess = postprocess, after_each = after_each },
                wrapped_callback
            )
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
    local filetype, method, params, postprocess, callback, after_each =
        opts.filetype, opts.method, opts.params, opts.postprocess, opts.callback, opts.after_each
    local generators = M.get_available(filetype, method)

    M.run(generators, params, { postprocess = postprocess, after_each = after_each }, callback)
end

M.run_registered_sequentially = function(opts)
    local filetype, method, make_params, postprocess, callback, after_each, after_all =
        opts.filetype, opts.method, opts.make_params, opts.postprocess, opts.callback, opts.after_each, opts.after_all
    local generators = M.get_available(filetype, method)

    M.run_sequentially(
        generators,
        make_params,
        { postprocess = postprocess, after_each = after_each, after_all = after_all },
        callback
    )
end

M.get_available = function(filetype, method)
    local available = {}
    for _, source in ipairs(require("null-ls.sources").get_available(filetype, method)) do
        table.insert(available, source.generator)
    end
    return available
end

M.can_run = function(filetype, method)
    return #M.get_available(filetype, method) > 0
end

return M
