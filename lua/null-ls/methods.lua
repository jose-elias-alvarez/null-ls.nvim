local methods = {
    CODE_ACTION = "textDocument/codeAction",
    DIAGNOSTICS = "textDocument/publishDiagnostics"
}

function methods:exists(method)
    return vim.tbl_contains(vim.tbl_values(self), method)
end

return methods
