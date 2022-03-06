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
    DID_SAVE = "textDocument/didSave",
    HOVER = "textDocument/hover",
    COMPLETION = "textDocument/completion",
}
vim.tbl_add_reverse_lookup(lsp_methods)

local internal_methods = {
    CODE_ACTION = "NULL_LS_CODE_ACTION",
    DIAGNOSTICS = "NULL_LS_DIAGNOSTICS",
    DIAGNOSTICS_ON_OPEN = "NULL_LS_DIAGNOSTICS_ON_OPEN",
    DIAGNOSTICS_ON_SAVE = "NULL_LS_DIAGNOSTICS_ON_SAVE",
    FORMATTING = "NULL_LS_FORMATTING",
    RANGE_FORMATTING = "NULL_LS_RANGE_FORMATTING",
    HOVER = "NULL_LS_HOVER",
    COMPLETION = "NULL_LS_COMPLETION",
}
vim.tbl_add_reverse_lookup(internal_methods)

local lsp_to_internal_map = {
    [lsp_methods.CODE_ACTION] = internal_methods.CODE_ACTION,
    [lsp_methods.FORMATTING] = internal_methods.FORMATTING,
    [lsp_methods.RANGE_FORMATTING] = internal_methods.RANGE_FORMATTING,
    [lsp_methods.DID_CHANGE] = internal_methods.DIAGNOSTICS,
    [lsp_methods.DID_SAVE] = internal_methods.DIAGNOSTICS_ON_SAVE,
    [lsp_methods.DID_OPEN] = internal_methods.DIAGNOSTICS_ON_OPEN,
    [lsp_methods.HOVER] = internal_methods.HOVER,
    [lsp_methods.COMPLETION] = internal_methods.COMPLETION,
}

local overrides = {
    [internal_methods.DIAGNOSTICS_ON_OPEN] = {
        [internal_methods.DIAGNOSTICS] = true,
        [internal_methods.DIAGNOSTICS_ON_SAVE] = true,
    },
}

-- extracted from Neovim's lsp.lua
local request_name_to_capability = {
    ["textDocument/hover"] = "hover",
    ["textDocument/signatureHelp"] = "signature_help",
    ["textDocument/definition"] = "goto_definition",
    ["textDocument/implementation"] = "implementation",
    ["textDocument/declaration"] = "declaration",
    ["textDocument/typeDefinition"] = "type_definition",
    ["textDocument/documentSymbol"] = "document_symbol",
    ["textDocument/prepareCallHierarchy"] = "call_hierarchy",
    ["textDocument/rename"] = "rename",
    ["textDocument/prepareRename"] = "rename",
    ["textDocument/codeAction"] = "code_action",
    ["textDocument/codeLens"] = "code_lens",
    ["codeLens/resolve"] = "code_lens_resolve",
    ["workspace/executeCommand"] = "execute_command",
    ["workspace/symbol"] = "workspace_symbol",
    ["textDocument/references"] = "find_references",
    ["textDocument/rangeFormatting"] = "document_range_formatting",
    ["textDocument/formatting"] = "document_formatting",
    ["textDocument/completion"] = "completion",
    ["textDocument/documentHighlight"] = "document_highlight",
}

local M = {}
M.lsp = lsp_methods
M.internal = internal_methods
M.map = lsp_to_internal_map
M.overrides = overrides
M.request_name_to_capability = request_name_to_capability

--- converts an internal null-ls method into its readable name
--- e.g. NULL_LS_FORMATTING > formatting
---@param m string internal method
---@return string
M.get_readable_name = function(m)
    assert(internal_methods[m], "failed to get name for method " .. m)
    return internal_methods[m]:lower()
end

return M
