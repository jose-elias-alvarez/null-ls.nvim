local cmd_resolver = require("null-ls.helpers.command_resolver")
local u = require("null-ls.utils")

local function make_builtin(opts)
    local method, filetypes, extra_filetypes, disabled_filetypes, factory, condition, config, can_run, generator_opts, generator =
        opts.method,
        opts.filetypes,
        opts.extra_filetypes,
        opts.disabled_filetypes,
        opts.factory,
        opts.condition,
        opts.config,
        opts.can_run,
        vim.deepcopy(opts.generator_opts) or {},
        vim.deepcopy(opts.generator) or {}

    factory = factory or function(_)
        generator.opts = generator_opts
        return generator
    end

    if extra_filetypes then
        filetypes = u.table.uniq(vim.list_extend(filetypes, extra_filetypes))
    end

    -- merge valid user opts w/ generator opts
    generator_opts = vim.tbl_deep_extend("force", generator_opts, {
        args = opts.args,
        check_exit_code = opts.check_exit_code,
        command = opts.command,
        env = opts.env,
        cwd = opts.cwd,
        diagnostics_format = opts.diagnostics_format,
        diagnostic_config = opts.diagnostic_config,
        filter = opts.filter,
        diagnostics_postprocess = opts.diagnostics_postprocess,
        dynamic_command = opts.dynamic_command,
        ignore_stderr = opts.ignore_stderr,
        runtime_condition = opts.runtime_condition,
        timeout = opts.timeout,
        to_temp_file = opts.to_temp_file,
        temp_dir = opts.temp_dir,
        prepend_extra_args = opts.prepend_extra_args,
        -- this isn't ideal, but since we don't have a way to modify on_output's behavior,
        -- it's better than nothing
        on_output = opts.on_output,
    })

    local builtin = {
        _opts = generator_opts,
        can_run = can_run,
        condition = condition,
        config = config,
        disabled_filetypes = disabled_filetypes,
        filetypes = filetypes,
        meta = opts.meta or {},
        method = method,
        name = opts.name or generator_opts.command,
    }

    setmetatable(builtin, {
        __index = function(tab, key)
            return key == "generator" and factory(generator_opts) or rawget(tab, key)
        end,
    })

    if opts.extra_args then
        local original_args, original_extra_args = generator_opts.args, opts.extra_args
        local prepend_extra_args = generator_opts.prepend_extra_args
        generator_opts.args = function(params)
            local original_args_copy = u.handle_function_opt(original_args, params) or {}
            local extra_args_copy = u.handle_function_opt(original_extra_args, params) or {}
            local args

            if prepend_extra_args then
                args = vim.list_extend(extra_args_copy, original_args_copy)
            else
                -- make sure "-" stays last
                if original_args_copy[#original_args_copy] == "-" then
                    table.remove(original_args_copy)
                    table.insert(extra_args_copy, "-")
                end
                args = vim.list_extend(original_args_copy, extra_args_copy)
            end
            return args
        end
    end

    local prefer_local, only_local = opts.prefer_local, opts.only_local
    -- override in case both are set
    if only_local then
        prefer_local = nil
    end

    if prefer_local or only_local then
        local maybe_prefix = prefer_local or only_local
        local prefix = type(maybe_prefix) == "string" and maybe_prefix or nil
        local resolver = cmd_resolver.generic(prefix)

        generator_opts.dynamic_command = function(params)
            local resolved_command = resolver(params) or (prefer_local and params.command)
            return resolved_command
        end
    end

    generator_opts._last_command = nil
    generator_opts._last_args = nil
    generator_opts._last_cwd = nil

    builtin.with = function(user_opts)
        return make_builtin(vim.tbl_extend("force", opts, user_opts))
    end

    return builtin
end

return make_builtin
