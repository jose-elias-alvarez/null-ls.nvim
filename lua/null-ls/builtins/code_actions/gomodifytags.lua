local h = require("null-ls.helpers")
local log = require("null-ls.logger")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local CODE_ACTION = methods.internal.CODE_ACTION

local treesitter_get_node_text = vim.treesitter.get_node_text
if not u.has_version("0.9.0") then
    treesitter_get_node_text = vim.treesitter.query.get_node_text
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
        return u.is_executable("gomodifytags")
    end,
    generator_opts = {
        command = "gomodifytags",
        args = { "-quiet" },
    },
    factory = function(opts)
        return {
            fn = function(params)
                -- Global vars
                local bufnr = params.bufnr
                local bufname = params.bufname
                local row = params.range.row
                local col = params.range.col

                -- Execution helpers
                local exec = function(struct_name, field_name, op, tag)
                    local cmd_opts = vim.list_extend(
                        { opts.command },
                        opts.args or {} -- customizable common args
                    )
                    vim.list_extend(cmd_opts, { "-w", "-file", bufname, "-struct", struct_name })
                    if field_name ~= nil then
                        vim.list_extend(cmd_opts, { "-field", field_name })
                    end
                    vim.list_extend(cmd_opts, { op, tag })

                    vim.fn.execute(":update") -- write when the buffer has been modified
                    local cmd = table.concat(cmd_opts, " ")
                    local output = vim.fn.system(cmd)
                    if vim.api.nvim_get_vvar("shell_error") == 0 then
                        vim.fn.execute(":e " .. bufname) -- reload the file
                    else
                        log:error(output) -- print error message
                    end
                end
                local get_input_tag_and_exec = function(struct_name, field_name, op)
                    vim.ui.input({ prompt = "Enter tags: " }, function(tag)
                        if tag == nil then
                            return
                        end
                        exec(struct_name, field_name, op, tag)
                    end)
                end
                local add_tags = function(struct_name, field_name)
                    return {
                        title = "gomodifytags: add tags",
                        action = function()
                            get_input_tag_and_exec(struct_name, field_name, "-add-tags")
                        end,
                    }
                end
                local remove_tags = function(struct_name, field_name)
                    return {
                        title = "gomodifytags: remove tags",
                        action = function()
                            get_input_tag_and_exec(struct_name, field_name, "-remove-tags")
                        end,
                    }
                end
                local clear_tags = function(struct_name, field_name)
                    return {
                        title = "gomodifytags: clear tags",
                        action = function()
                            exec(struct_name, field_name, "-clear-tags", nil)
                        end,
                    }
                end
                local add_options = function(struct_name, field_name)
                    return {
                        title = "gomodifytags: add options",
                        action = function()
                            get_input_tag_and_exec(struct_name, field_name, "-add-options")
                        end,
                    }
                end
                local remove_options = function(struct_name, field_name)
                    return {
                        title = "gomodifytags: remove options",
                        action = function()
                            get_input_tag_and_exec(struct_name, field_name, "-remove-options")
                        end,
                    }
                end
                local clear_options = function(struct_name, field_name)
                    return {
                        title = "gomodifytags: clear options",
                        action = function()
                            exec(struct_name, field_name, "-clear-options", nil)
                        end,
                    }
                end
                -- End of Execution helpers

                -- Main
                local tsnode
                if u.has_version("0.9.0") then
                    tsnode = vim.treesitter.get_node({ bufnr = bufnr, row = row - 1, col = col - 1 })
                else
                    tsnode = vim.treesitter.get_node_at_pos(bufnr, row - 1, col - 1, {})
                end
                local actions = {}
                local struct_name

                if tsnode == nil then
                    return actions
                end

                -- Ops on struct
                if (tsnode:type()) == "type_identifier" then
                    local tspnode = tsnode:parent()
                    if tspnode == nil or tspnode:type() ~= "type_spec" then
                        return
                    end
                    local typename_node = tspnode:field("type")[1]
                    if typename_node == nil or typename_node:type() ~= "struct_type" then
                        return
                    end

                    struct_name = treesitter_get_node_text(tsnode, 0)
                    if struct_name == nil then
                        return
                    end

                    table.insert(actions, add_tags(struct_name))
                    table.insert(actions, remove_tags(struct_name))
                    table.insert(actions, clear_tags(struct_name))

                    table.insert(actions, add_options(struct_name))
                    table.insert(actions, remove_options(struct_name))
                    table.insert(actions, clear_options(struct_name))
                    return actions
                end

                -- Ops on struct field
                if (tsnode:type()) == "field_identifier" then
                    local field_name = treesitter_get_node_text(tsnode, 0)
                    local tspnode = tsnode:parent():parent():parent()
                    if tspnode ~= nil and (tspnode:type()) == "struct_type" then
                        tspnode = tspnode:parent():child(0)
                        struct_name = treesitter_get_node_text(tspnode, 0)
                    end

                    if struct_name == nil or field_name == nil then
                        return
                    end

                    table.insert(actions, add_tags(struct_name, field_name))
                    table.insert(actions, remove_tags(struct_name, field_name))
                    table.insert(actions, clear_tags(struct_name, field_name))

                    table.insert(actions, add_options(struct_name, field_name))
                    table.insert(actions, remove_options(struct_name, field_name))
                    table.insert(actions, clear_options(struct_name, field_name))
                    return actions
                end
            end,
        }
    end,
})
