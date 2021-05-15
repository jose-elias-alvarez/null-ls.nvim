local methods = {
    CODE_ACTION = "textDocument/codeAction",
    DIAGNOSTICS = "textDocument/publishDiagnostics",
    INITIALIZE = "initialize",
    SHUTDOWN = "shutdown",
    EXECUTE_COMMAND = "workspace/executeCommand"
}

function methods:exists(method)
    return vim.tbl_contains(vim.tbl_values(self), method)
end

return methods
