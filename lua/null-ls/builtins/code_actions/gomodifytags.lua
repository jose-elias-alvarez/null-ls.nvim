local h = require("null-ls.helpers")
local log = require("null-ls.logger")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

local BIN = "gomodifytags -w -quiet "

local exec = function(bufname, struct_name, field_name, op, tag)
    local opts = {}
    table.insert(opts, "-file")
    table.insert(opts, bufname)
    table.insert(opts, "-struct")
    table.insert(opts, struct_name)
    if field_name ~= nil then
        table.insert(opts, "-field")
        table.insert(opts, field_name)
    end
    table.insert(opts, op)
    table.insert(opts, tag)

    vim.fn.execute(":update") -- write when the buffer has been modified
    local cmd = BIN .. table.concat(opts, " ")
    local output = vim.fn.system(cmd)
    if vim.api.nvim_get_vvar("shell_error") == 0 then
        vim.fn.execute(":e " .. bufname) -- reload the file
    else
        log:error(output) -- print error message
    end
end

local get_input_tag_and_exec = function(bufname, struct_name, field_name, op)
    vim.ui.input({ prompt = "Enter tags: " }, function(tag)
        if tag == nil then
            return
        end
        exec(bufname, struct_name, field_name, op, tag)
    end)
end

local add_tags = function(bufname, struct_name, field_name)
    return {
        title = "gomodifytags: add tags",
        action = function()
            get_input_tag_and_exec(bufname, struct_name, field_name, "-add-tags")
        end,
    }
end

local remove_tags = function(bufname, struct_name, field_name)
    return {
        title = "gomodifytags: remove tags",
        action = function()
            get_input_tag_and_exec(bufname, struct_name, field_name, "-remove-tags")
        end,
    }
end

local clear_tags = function(bufname, struct_name, field_name)
    return {
        title = "gomodifytags: clear tags",
        action = function()
            exec(bufname, struct_name, field_name, "-clear-tags", nil)
        end,
    }
end

local add_options = function(bufname, struct_name, field_name)
    return {
        title = "gomodifytags: add options",
        action = function()
            get_input_tag_and_exec(bufname, struct_name, field_name, "-add-options")
        end,
    }
end

local remove_options = function(bufname, struct_name, field_name)
    return {
        title = "gomodifytags: remove options",
        action = function()
            get_input_tag_and_exec(bufname, struct_name, field_name, "-remove-options")
        end,
    }
end

local clear_options = function(bufname, struct_name, field_name)
    return {
        title = "gomodifytags: clear options",
        action = function()
            exec(bufname, struct_name, field_name, "-clear-options", nil)
        end,
    }
end

return h.make_builtin({
    name = "gomodifytags",
    meta = {
        url = "https://github.com/fatih/gomodifytags",
        description = "Go tool to modify struct field tags",
        notes = { "Requires installing the Go tree-sitter parser." },
    },
    method = CODE_ACTION,
    filetypes = { "go" },
    can_run = function()
        return require("null-ls.utils").is_executable("gomodifytags")
    end,
    generator = {
        fn = function(params)
            local bufnr = params.bufnr
            local bufname = params.bufname

            local row = params.range.row
            local col = params.range.col
            local tsnode = vim.treesitter.get_node_at_pos(bufnr, row - 1, col - 1, {})

            local actions = {}
            local struct_name

            -- struct
            if (tsnode:type()) == "type_identifier" then
                struct_name = vim.treesitter.query.get_node_text(tsnode, 0)
                if struct_name == nil then
                    return
                end

                table.insert(actions, add_tags(bufname, struct_name))
                table.insert(actions, remove_tags(bufname, struct_name))
                table.insert(actions, clear_tags(bufname, struct_name))

                table.insert(actions, add_options(bufname, struct_name))
                table.insert(actions, remove_options(bufname, struct_name))
                table.insert(actions, clear_options(bufname, struct_name))
                return actions
            end

            -- struct field
            if (tsnode:type()) == "field_identifier" then
                local field_name = vim.treesitter.query.get_node_text(tsnode, 0)
                local tspnode = tsnode:parent():parent():parent()
                if tspnode ~= nil and (tspnode:type()) == "struct_type" then
                    tspnode = tspnode:parent():child(0)
                    struct_name = vim.treesitter.query.get_node_text(tspnode, 0)
                end

                if struct_name == nil or field_name == nil then
                    return
                end

                table.insert(actions, add_tags(bufname, struct_name, field_name))
                table.insert(actions, remove_tags(bufname, struct_name, field_name))
                table.insert(actions, clear_tags(bufname, struct_name, field_name))

                table.insert(actions, add_options(bufname, struct_name, field_name))
                table.insert(actions, remove_options(bufname, struct_name, field_name))
                table.insert(actions, clear_options(bufname, struct_name, field_name))
                return actions
            end
        end,
    },
})
