local s = require("null-ls.state")
local cmd_resolver = require("null-ls.helpers.command_resolver")
local u = require("null-ls.utils")

local function make_builtin(opts)
    local method, filetypes, extra_filetypes, disabled_filetypes, factory, condition, generator_opts, generator =
        opts.method,
        opts.filetypes,
        opts.extra_filetypes,
        opts.disabled_filetypes,
        opts.factory,
        opts.condition,
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
        command = opts.command,
        env = opts.env,
        cwd = opts.cwd,
        diagnostics_format = opts.diagnostics_format,
        diagnostics_postprocess = opts.diagnostics_postprocess,
        dynamic_command = opts.dynamic_command,
        ignore_stderr = opts.ignore_stderr,
        runtime_condition = opts.runtime_condition,
        timeout = opts.timeout,
        to_temp_file = opts.to_temp_file,
        -- this isn't ideal, but since we don't have a way to modify on_output's behavior,
        -- it's better than nothing
        on_output = opts.on_output,
    })

    local builtin = {
        method = method,
        filetypes = filetypes,
        disabled_filetypes = disabled_filetypes,
        condition = condition,
        name = opts.name or generator_opts.command,
        _opts = generator_opts,
        meta = opts.meta or {},
    }

    setmetatable(builtin, {
        __index = function(tab, key)
            return key == "generator" and factory(generator_opts) or rawget(tab, key)
        end,
    })

    if opts.extra_args then
        local original_args, original_extra_args = generator_opts.args, opts.extra_args
        generator_opts.args = function(params)
            local original_args_copy = u.handle_function_opt(original_args, params) or {}
            local extra_args_copy = u.handle_function_opt(original_extra_args, params) or {}

            -- make sure "-" stays last
            if original_args_copy[#original_args_copy] == "-" then
                table.remove(original_args_copy)
                table.insert(extra_args_copy, "-")
            end

            return vim.list_extend(original_args_copy, extra_args_copy)
        end
    end

    local prefer_local, only_local = opts.prefer_local, opts.only_local
    -- override in case both are set
    if only_local then
        prefer_local = nil
    end

    if prefer_local or only_local then
        generator_opts.dynamic_command = function(params)
            local maybe_prefix = prefer_local or only_local
            local prefix = type(maybe_prefix) == "string" and maybe_prefix
            local resolved_command = cmd_resolver.generic(params, prefix) or (prefer_local and params.command)
            return resolved_command
        end

        generator_opts.cwd = generator_opts.cwd
            or function(params)
                local resolved = s.get_resolved_command(params.bufnr, params.command)
                return resolved and resolved.cwd
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
