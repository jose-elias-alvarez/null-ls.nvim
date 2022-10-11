local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local api = vim.api

---@class LspParams
---@field client_id number
---@field method string
---@field options table
---@field range LspRange|nil
---@field bufnr number|nil
---@field textDocument { uri: string, text: string|nil }
---@field contentChanges { text: string }[]

--- resolves bufnr from LSP params
---@param lsp_params LspParams
---@return number bufnr
local resolve_bufnr = function(lsp_params)
    -- if already set, return
    if lsp_params.bufnr then
        return lsp_params.bufnr
    end

    -- get from uri
    if lsp_params.textDocument and lsp_params.textDocument.uri then
        return vim.uri_to_bufnr(lsp_params.textDocument.uri)
    end

    -- fallback
    return api.nvim_get_current_buf()
end

--- resolves buffer content from LSP params when possible
---@param lsp_params LspParams
---@param bufnr number
---@return string[] content
local resolve_content = function(lsp_params, bufnr)
    -- textDocument/didOpen sends full buffer content
    if lsp_params.method == methods.lsp.DID_OPEN and lsp_params.textDocument and lsp_params.textDocument.text then
        local content = u.split_at_newline(bufnr, lsp_params.textDocument.text)
        return content
    end

    -- textDocument/didChange sends full buffer content if configured
    if
        lsp_params.method == methods.lsp.DID_CHANGE
        and lsp_params.contentChanges
        and lsp_params.contentChanges[1]
        and lsp_params.contentChanges[1].text
    then
        local content = u.split_at_newline(bufnr, lsp_params.contentChanges[1].text)
        return content
    end

    -- fall back to API method
    return u.buf.content(bufnr) --[=[@as string[]]=]
end

--- gets word to complete for use in completion sources
---@param params NullLsParams
---@return string word_to_complete
local get_word_to_complete = function(params)
    local line = params.content[params.row]
    local line_to_cursor = line:sub(1, params.col)
    local regex = vim.regex("\\k*$")

    return line:sub(regex:match_str(line_to_cursor) + 1, params.col)
end

---@class NullLsParams
---@field client_id number null-ls client id
---@field lsp_method string|nil original LSP method
---@field lsp_params LspParams
---@field options table|nil options from LSP params (e.g. formattingOptions)
---@field content string[] buffer content
---@field bufnr number
---@field method string null-ls method
---@field row number current row number
---@field col number current column number
---@field bufname string
---@field filetype string buffer
---@field ft string buffer alias for filetype
---@field range NullLsRange|nil converted LSP range
---@field word_to_complete string|nil
---@field _pos number[]
---@field source_id number set by generators.run
---@field command string|nil set by generator_factory
---@field root string|nil set by generator_factory
local Params = {}

function Params:get_source()
    local source_id = self.source_id
    local source = require("null-ls.sources").get({ id = source_id })[1]
    assert(source, "failed to resolve source from params")

    return source
end

function Params:get_config()
    local source = self:get_source()
    return source.config or {}
end

function Params:new(params)
    return setmetatable(params, {
        ---@param t NullLsParams
        ---@param k string index key
        __index = function(t, k)
            -- lazily resolve potentially unnecessary keys
            if k == "content" then
                local content = resolve_content(t.lsp_params, t.bufnr)
                rawset(t, k, content)
                return content
            end

            if k == "bufname" then
                local bufname = api.nvim_buf_get_name(t.bufnr)
                rawset(t, k, bufname)
                return bufname
            end

            if k == "ft" or k == "filetype" then
                local ft = api.nvim_buf_get_option(t.bufnr, "filetype")
                rawset(t, k, ft)
                return ft
            end

            if k == "_pos" then
                local pos = api.nvim_win_get_cursor(0)
                rawset(t, k, pos)
                return pos
            end

            if k == "row" then
                return t._pos[1]
            end
            if k == "col" then
                return t._pos[2]
            end

            -- range formatting sources
            if k == "range" then
                assert(t.lsp_params.range, "LSP params do not specify range")

                local range = u.range.from_lsp(t.lsp_params.range)
                rawset(t, k, range)
                return range
            end

            -- completion sources
            if k == "word_to_complete" then
                local word_to_complete = get_word_to_complete(t)
                rawset(t, k, word_to_complete)
                return word_to_complete
            end

            return rawget(t, k) or Params[k]
        end,
    })
end

---@param lsp_params LspParams
---@param method string null-ls method
---@return NullLsParams
return function(lsp_params, method)
    return Params:new({
        client_id = lsp_params.client_id,
        lsp_method = lsp_params.method,
        lsp_params = lsp_params,
        options = lsp_params.options,
        method = method,
        bufnr = resolve_bufnr(lsp_params),
    })
end
