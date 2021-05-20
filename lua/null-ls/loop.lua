local u = require("null-ls.utils")

local api = vim.api
local uv = vim.loop
local validate = vim.validate

local close_handle = function(handle)
    if handle and not handle:is_closing() then handle:close() end
end

local parse_args = function(args, bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    local parsed = {}
    for _, arg in pairs(args) do
        if string.find(arg, "$FILENAME") then
            arg = u.string.replace(arg, "$FILENAME",
                                   api.nvim_buf_get_name(bufnr))
        end
        if string.find(arg, "$TEXT") then
            arg = u.string.replace(arg, "$TEXT", u.buf.content(bufnr, true))
        end

        table.insert(parsed, arg)
    end
    return parsed
end

local M = {}

M.spawn = function(cmd, args, opts)
    local handler, input, bufnr = opts.handler, opts.input, opts.bufnr

    validate({
        handler = {handler, "function"},
        input = {input, "string", true},
        bufnr = {bufnr, "number", true}
    })

    local output, error_output = "", ""
    local handle_stdout = vim.schedule_wrap(
                              function(err, chunk)
            if err then error("stdout error: " .. err) end

            if chunk then output = output .. chunk end
            if not chunk then
                if output == "" then output = nil end
                if error_output == "" then error_output = nil end

                handler(error_output, output)
            end
        end)

    local handle_stderr = function(err, chunk)
        if err then error("stderr error: " .. err) end

        if chunk then error_output = error_output .. chunk end
    end

    local stdin = uv.new_pipe(true)
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local stdio = {stdin, stdout, stderr}

    local handle
    handle = uv.spawn(cmd, {args = parse_args(args, bufnr), stdio = stdio},
                      vim.schedule_wrap(function()
        stdout:read_stop()
        stderr:read_stop()

        close_handle(stdin)
        close_handle(stdout)
        close_handle(stderr)
        close_handle(handle)
    end))

    uv.read_start(stdout, handle_stdout)
    uv.read_start(stderr, handle_stderr)

    if input then stdin:write(input, function() stdin:close() end) end
end

if _G._TEST then M._parse_args = parse_args end

return M
