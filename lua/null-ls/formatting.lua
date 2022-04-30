local log = require("null-ls.logger")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local api = vim.api
local lsp = vim.lsp

local postprocess = function(edit, params)
    edit.row = edit.row or 1
    edit.col = edit.col or 1
    edit.end_row = edit.end_row or #params.content + 1
    edit.end_col = edit.end_col or 1

    edit.range = u.range.to_lsp(edit)
    -- strip trailing newline
    edit.newText = edit.text:gsub("[\r\n]$", "")
end

local M = {}

M.handler = function(method, original_params, handler)
    if not original_params.textDocument then
        return
    end

    if method == methods.lsp.FORMATTING or method == methods.lsp.RANGE_FORMATTING then
        local bufnr = vim.uri_to_bufnr(original_params.textDocument.uri)

        -- copy content and options to temp buffer
        local temp_bufnr = api.nvim_create_buf(false, true)
        api.nvim_buf_set_option(temp_bufnr, "eol", api.nvim_buf_get_option(bufnr, "eol"))
        api.nvim_buf_set_option(temp_bufnr, "fixeol", api.nvim_buf_get_option(bufnr, "fixeol"))
        api.nvim_buf_set_option(temp_bufnr, "fileformat", api.nvim_buf_get_option(bufnr, "fileformat"))
        api.nvim_buf_set_lines(temp_bufnr, 0, -1, false, api.nvim_buf_get_lines(bufnr, 0, -1, false))

        local called_handler = false
        local handler_wrapper = function(...)
            -- don't call handler if buffer was unloaded, e.g. on :wq
            if not api.nvim_buf_is_loaded(bufnr) then
                return
            end

            -- calling handler twice breaks sync formatting
            if called_handler then
                return
            end

            -- schedule before calling handler in case handler throws
            vim.schedule(function()
                api.nvim_buf_delete(temp_bufnr, { force = true })
            end)

            handler(...)
            called_handler = true
        end

        local handle_err = function(err)
            log:warn("error in formatting handler: " .. err)
            -- after error, call handler w/ empty response to prevent timeout
            handler_wrapper()
        end

        local make_params = function()
            local params = u.make_params(original_params, methods.map[method])
            -- override actual content w/ temp buffer content
            params.content = u.buf.content(temp_bufnr)
            return params
        end

        local after_each = function(edits)
            local ok, err = pcall(
                lsp.util.apply_text_edits,
                edits,
                temp_bufnr,
                require("null-ls.client").get_offset_encoding()
            )
            if not ok then
                handle_err(err)
            end
        end

        local callback = function()
            local ok, err = pcall(function()
                local edits = require("null-ls.diff").compute_diff(
                    u.buf.content(bufnr),
                    u.buf.content(temp_bufnr),
                    u.get_line_ending(bufnr)
                )
                local is_actual_edit = not (edits.newText == "" and edits.rangeLength == 0)

                if is_actual_edit then
                    log:debug("received edits from generators")
                    log:trace(edits)
                end

                handler_wrapper(is_actual_edit and { edits } or nil)
            end)

            if not ok then
                handle_err(err)
            end
        end

        require("null-ls.generators").run_registered_sequentially({
            filetype = api.nvim_buf_get_option(bufnr, "filetype"),
            method = methods.map[method],
            make_params = make_params,
            postprocess = postprocess,
            after_each = after_each,
            callback = callback,
        })

        original_params._null_ls_handled = true
    end
end

return M
