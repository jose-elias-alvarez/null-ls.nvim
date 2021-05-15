local methods = require("null-ls.methods")

local rpc_error = vim.lsp.rpc.rpc_response_error
local chansend = vim.fn.chansend
local json = {decode = vim.fn.json_decode, encode = vim.fn.json_encode}

local format_rpc_message = function(encoded)
    return table.concat({
        "Content-Length: ", tostring(#encoded), "\r\n\r\n", encoded
    })
end

local capabilities = {codeActionProvider = true, executeCommandProvider = true}

return function()
    local lsp_id
    vim.fn.stdioopen({
        on_stdin = function(chan_id, input)
            local send = function(response)
                response.id = lsp_id
                chansend(chan_id, format_rpc_message(json.encode(response)))
            end

            local data = ""
            for i, chunk in ipairs(input) do
                -- skip header
                if i > 2 then data = data .. chunk end
            end

            local ok, decoded = pcall(json.decode, data)
            if not ok then
                -- TODO: improve error handling
                send({error = rpc_error(-32700)})
                return
            end

            local method, id = decoded.method, decoded.id
            lsp_id = id and id

            if method == methods.INITIALIZE then
                send({result = {capabilities = capabilities}})
                return
            end

            if method == methods.SHUTDOWN then
                send({result = nil})
                vim.cmd("noa qa!")
            end

            -- these should be caught by client.request and never reach the server,
            -- but since the server declares these capabilities, they're here as fallbacks
            if method == methods.EXECUTE_COMMAND then
                send({result = nil})
            end

            if method == methods.CODE_ACTION then
                send({result = nil})
            end
        end
    })
end
