return function(opts)
    -- ignore errors unless otherwise specified
    if opts.ignore_stderr == nil then
        opts.ignore_stderr = true
    end

    -- for formatters, to_temp_file only works if from_temp_file is also set
    if opts.to_temp_file then
        opts.from_temp_file = true
    end

    opts.on_output = function(params, done)
        local output = params.output
        if not output then
            return done()
        end

        return done({ { text = output } })
    end

    return require("null-ls.helpers").generator_factory(opts)
end
