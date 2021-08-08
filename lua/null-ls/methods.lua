local lsp_methods = {
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

local internal_methods = {
    CODE_ACTION = "NULL_LS_CODE_ACTION",
    DIAGNOSTICS = "NULL_LS_DIAGNOSTICS",
    FORMATTING = "NULL_LS_FORMATTING",
    RANGE_FORMATTING = "NULL_LS_RANGE_FORMATTING",
}

local lsp_to_internal_map = {
    [lsp_methods.CODE_ACTION] = internal_methods.CODE_ACTION,
    [lsp_methods.FORMATTING] = internal_methods.FORMATTING,
    [lsp_methods.RANGE_FORMATTING] = internal_methods.RANGE_FORMATTING,
    [lsp_methods.DID_OPEN] = internal_methods.DIAGNOSTICS,
    [lsp_methods.DID_CHANGE] = internal_methods.DIAGNOSTICS,
}

return { lsp = lsp_methods, internal = internal_methods, map = lsp_to_internal_map }
