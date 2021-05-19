local methods = require("null-ls.methods")

local rpc_error = vim.lsp.rpc.rpc_response_error
local chansend = vim.fn.chansend
local json = {decode = vim.fn.json_decode, encode = vim.fn.json_encode}

local decode_rpc_data = function(encoded)
    local data = ""
    for i, chunk in ipairs(encoded) do
        -- skip header
        if i > 2 then data = data .. chunk end
    end

    local ok, decoded = pcall(json.decode, data)
    return ok and decoded or nil
end

local format_rpc_message = function(encoded)
    return table.concat({
        "Content-Length: ", tostring(#encoded), "\r\n\r\n", encoded
    })
end

local capabilities = {
    codeActionProvider = true,
    executeCommandProvider = true,
    textDocumentSync = {change = 1, openClose = true}
}

local M = {}
M.capabilities = capabilities

M.start = function()
    local lsp_id
    local on_stdin = function(chan_id, input)
        local send = function(response)
            response.id = lsp_id
            chansend(chan_id, format_rpc_message(json.encode(response)))
        end

        local decoded = decode_rpc_data(input)
        if not decoded then
            -- TODO: improve error handling
            send({error = rpc_error(-32700)})
            return
        end

        local method, id = decoded.method, decoded.id
        lsp_id = id

        if method == methods.lsp.INITIALIZE then
            send({result = {capabilities = capabilities}})
            return
        end

        if method == methods.lsp.SHUTDOWN then
            send({result = nil})
            vim.cmd("noa qa!")
        end

        -- these should be caught by the client and never reach the server,
        -- but since the server declares these capabilities, they're here as fallbacks
        if method == methods.lsp.EXECUTE_COMMAND then
            send({result = nil})
        end

        if method == methods.lsp.CODE_ACTION then send({result = nil}) end

        if method == methods.lsp.DID_CHANGE then send({result = nil}) end
    end

    vim.fn.stdioopen({on_stdin = on_stdin})
end

return M
