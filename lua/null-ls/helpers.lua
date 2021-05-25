local u = require("null-ls.utils")
local loop = require("null-ls.loop")
local methods = require("null-ls.methods")

local validate = vim.validate

local M = {}

local get_content = function(params)
    -- when possible, get content from params
    if params.content then return table.concat(params.content, "\n") end

    -- otherwise, get content directly
    return u.buf.content(params.bufnr, true)
end

local json_output_wrapper = function(params, done, on_output)
    local ok, decoded = pcall(vim.fn.json_decode, params.output)
    if not ok then error("failed to decode json: " .. decoded) end

    params.output = decoded
    done(on_output(params))
end

local line_output_wrapper = function(params, done, on_output)
    local output = params.output
    if not output then
        done()
        return
    end

    local all_results = {}
    for _, line in ipairs(vim.split(output, "\n")) do
        if line ~= "" then
            local results = on_output(line, params)
            if type(results) == "table" then
                table.insert(all_results, results)
            end
        end
    end

    done(all_results)
end

local formats = {
    raw = "raw", -- receive error_output and output directly
    none = nil, -- same as raw but will not send error output
    line = "line", -- call handler once per line of output
    json = "json" -- send processed json output to handler
}

M.generator_factory = function(opts)
    return {
        fn = function(params, done)
            local command, args, on_output, format, to_stderr, to_stdin,
                  ignore_errors, check_exit_code = opts.command, opts.args,
                                                   opts.on_output, opts.format,
                                                   opts.to_stderr,
                                                   opts.to_stdin,
                                                   opts.ignore_errors,
                                                   opts.check_exit_code

            validate({
                command = {command, "string"},
                args = {args, "table", true},
                on_output = {on_output, "function"},
                format = {
                    format, function(a)
                        return not a or
                                   vim.tbl_contains(vim.tbl_values(formats), a)
                    end, "raw, line, or json"
                },
                to_stderr = {to_stderr, "boolean", true},
                to_stdin = {to_stdin, "boolean", true},
                ignore_errors = {ignore_errors, "boolean", true},
                check_exit_code = {check_exit_code, "function", true}
            })

            local wrapper = function(error_output, output)
                if to_stderr then
                    output = error_output
                    error_output = nil
                end

                if error_output and format ~= formats.raw then
                    if not ignore_errors then
                        error("error in generator output: " .. error_output)
                    end
                    return
                end

                params.output = output
                if format == formats.raw then
                    params.err = error_output
                end

                if format == formats.json then
                    json_output_wrapper(params, done, on_output)
                    return
                end
                if format == formats.line then
                    line_output_wrapper(params, done, on_output)
                    return
                end

                on_output(params, done)
            end

            loop.spawn(command, args or {}, {
                input = to_stdin and get_content(params) or nil,
                handler = wrapper,
                bufnr = params.bufnr,
                check_exit_code = check_exit_code
            })
        end,
        filetypes = opts.filetypes,
        async = true
    }
end

M.formatter_factory = function(opts)
    opts.ignore_errors = true
    opts.on_output = function(params, done)
        local output = params.output
        if not output then return done() end

        return done({
            {
                row = 0,
                col = 0,
                end_row = vim.tbl_count(params.content),
                end_col = -1,
                text = output
            }
        })
    end

    return M.generator_factory(opts)
end

if _G._TEST then
    M._json_output_wrapper = json_output_wrapper
    M._line_output_wrapper = line_output_wrapper
end

return M
