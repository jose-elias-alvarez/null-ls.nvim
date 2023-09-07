local h = require("null-ls.helpers")
local log = require("null-ls.logger")
local methods = require("null-ls.methods")

local DIAGNOSTICS = methods.internal.DIAGNOSTICS
local SEVERITIES = h.diagnostics.severities

local comment_types = {
    comment = true,
    comment_content = true,
    line_comment = true,
}

local function get_document_root(bufnr, filetype)
    local lang = vim.treesitter.language.get_lang(filetype)
    if not lang then
        log:debug("no lang available for filetype " .. filetype)
        return
    end

    local has_parser, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
    if not has_parser then
        log:debug("no parser available for lang " .. lang)
        return
    end

    local tree = parser:parse()[1]
    if not tree or not tree:root() or tree:root():type() == "ERROR" then
        return
    end

    return tree:root()
end

local function parse_comments(root, output)
    for node in root:iter_children() do
        if comment_types[node:type()] then
            table.insert(output, node)
        else
            parse_comments(node, output)
        end
    end
end

local function get_comments(bufnr, filetype)
    local document_root = get_document_root(bufnr, filetype)
    if not document_root then
        return {}
    end

    local output = {}
    parse_comments(document_root, output)
    return output
end

local keywords = {
    TODO = {
        severity = SEVERITIES.information,
    },
    FIX = {
        severity = SEVERITIES.error,
        alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
    },
    HACK = {
        severity = SEVERITIES.warning,
    },
    WARN = {
        severity = SEVERITIES.warning,
        alt = { "WARNING", "XXX" },
    },
    PERF = {
        severity = SEVERITIES.information,
        alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" },
    },
    NOTE = {
        severity = SEVERITIES.hint,
        alt = { "INFO" },
    },
}

local keyword_by_name = {}

for kw, opts in pairs(keywords) do
    keyword_by_name[kw] = kw
    for _, alt in pairs(opts.alt or {}) do
        keyword_by_name[alt] = kw
    end
end
return h.make_builtin({
    name = "todo_comments",
    meta = {
        description = "Uses inbuilt Lua code and treesitter to detect lines with TODO comments and show a diagnostic warning on each line where it's present.",
    },
    method = DIAGNOSTICS,
    filetypes = {},
    generator = {
        fn = function(params)
            local ft = params.ft
            local result = {}
            for _, node in ipairs(get_comments(params.bufnr, ft)) do
                local content = vim.treesitter.get_node_text(node, params.bufnr):match("^%s*(.*)")

                for kw, _ in pairs(keyword_by_name) do
                    if content:match("%f[%a]" .. kw .. "%f[%A]") and node:start() then
                        local row, col, _ = node:start()
                        local message = content:match("%f[%a]" .. kw .. "%f[%A].*$")

                        col = col + #content - #message

                        table.insert(result, {
                            message = message,
                            severity = keywords[keyword_by_name[kw]].severity,
                            row = row + 1,
                            col = col + 1,
                            source = "todo_comments",
                        })
                    end
                end
            end

            return result
        end,
    },
})
