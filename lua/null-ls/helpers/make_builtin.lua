local log = require("null-ls.logger")
local s = require("null-ls.state")
local u = require("null-ls.utils")

local function make_builtin(opts)
    local method, filetypes, disabled_filetypes, factory, condition, generator_opts, generator =
        opts.method,
        opts.filetypes,
        opts.disabled_filetypes,
        opts.factory,
        opts.condition,
        vim.deepcopy(opts.generator_opts) or {},
        vim.deepcopy(opts.generator) or {}

    factory = factory or function()
        generator.opts = generator_opts
        return generator
    end

    -- merge valid user opts w/ generator opts
    generator_opts = vim.tbl_deep_extend("force", generator_opts, {
        args = opts.args,
        command = opts.command,
        env = opts.env,
        cwd = opts.cwd,
        diagnostics_format = opts.diagnostics_format,
        dynamic_command = opts.dynamic_command,
        runtime_condition = opts.runtime_condition,
        timeout = opts.timeout,
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
            local resolved = s.get_resolved_command(params.bufnr, params.command)
            -- a string means command was resolved on last run
            -- false means the command already failed to resolve, so don't bother checking again
            if resolved and (type(resolved.command) == "string" or resolved.command == false) then
                return resolved.command
            end

            local maybe_prefix = prefer_local or only_local
            local prefix = type(maybe_prefix) == "string" and maybe_prefix
            local executable_to_find = prefix and u.path.join(prefix, params.command) or params.command
            log:debug("attempting to find local executable " .. executable_to_find)

            local root = u.get_root()

            local found, resolved_cwd
            u.path.traverse_parents(params.bufname, function(dir)
                found = u.path.join(dir, executable_to_find)
                if u.is_executable(found) then
                    resolved_cwd = dir
                    return true
                end

                found = nil
                resolved_cwd = nil
                -- use cwd as a stopping point to avoid scanning the entire file system
                if dir == root then
                    return true
                end
            end)

            local resolved_command = found or (prefer_local and params.command)
            if resolved_command then
                local is_executable, err_msg = u.is_executable(resolved_command)
                assert(is_executable, err_msg)
            end

            s.set_resolved_command(
                params.bufnr,
                params.command,
                { command = resolved_command or false, cwd = resolved_cwd }
            )
            return resolved_command
        end

        generator_opts.cwd = opts.cwd
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
