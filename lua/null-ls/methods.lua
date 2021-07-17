local M = {}
M.lsp = {
    INITIALIZE = "initialize",
    SHUTDOWN = "shutdown",
    EXIT = "exit",
    CODE_ACTION = "textDocument/codeAction",
    EXECUTE_COMMAND = "workspace/executeCommand",
    PUBLISH_DIAGNOSTICS = "textDocument/publishDiagnostics",
    FORMATTING = "textDocument/formatting",
    RANGE_FORMATTING = "textDocument/rangeFormatting",
    DID_CHANGE = "textDocument/didChange",
    DID_OPEN = "textDocument/didOpen",
    DID_CLOSE = "textDocument/didClose",
}

M.internal = {
    CODE_ACTION = "NULL_LS_CODE_ACTION",
    DIAGNOSTICS = "NULL_LS_DIAGNOSTICS",
    FORMATTING = "NULL_LS_FORMATTING",
    RANGE_FORMATTING = "NULL_LS_RANGE_FORMATTING",
    _NOTIFICATION = "NULL_LS_NOTIFICATION",
    _REQUEST_ID = 712345,
}

return M
