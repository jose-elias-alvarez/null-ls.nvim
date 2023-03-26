local h = require("null-ls.helpers")
local log = require("null-ls.logger")
local methods = require("null-ls.methods")
local u = require("null-ls.utils")

local CODE_ACTION = methods.internal.CODE_ACTION

local treesitter_get_node_text = vim.treesitter.get_node_text
if not u.has_version("0.9.0") then
    treesitter_get_node_text = vim.treesitter.query.get_node_text
end

local treesitter_query_parse = vim.treesitter.query.parse
if not u.has_version("0.9.0") then
    treesitter_query_parse = vim.treesitter.query.parse_query
end

return h.make_builtin({
    name = "impl",
    meta = {
        url = "https://github.com/josharian/impl",
        description = "impl generates method stubs for implementing an interface.",
        notes = { "Requires installing the Go tree-sitter parser." },
    },
    method = CODE_ACTION,
    filetypes = { "go" },
    can_run = function()
        return u.is_executable("impl")
    end,
    generator_opts = {
        command = "impl",
    },
    factory = function(opts)
        return {
            fn = function(params)
                local bufnr = params.bufnr
                local row = params.range.row
                local col = params.range.col

                local exec = function(receiver, interface)
                    local cmd_args = { opts.command, receiver, interface }

                    local output = vim.fn.system(cmd_args)
                    if vim.v.shell_error ~= 0 then
                        log:error(output)
                        return
                    end

                    return output
                end
                local get_receiver = function(type_spec_node, receiver_type)
                    local type_decl_node = type_spec_node:parent()
                    if not type_decl_node then
                        return
                    end
                    local parent_of_type_decl_node = type_decl_node:parent()
                    if not parent_of_type_decl_node then
                        return
                    end

                    -- Find methods of struct and try to get receiver names from them.
                    local methods_query = treesitter_query_parse(
                        "go",
                        string.format(
                            [[(
                                (method_declaration
                                  receiver: (parameter_list
                                    (parameter_declaration
                                      name: (identifier)? @name
                                      type: [
                                        (pointer_type (type_identifier) @type)
                                        (type_identifier) @type
                                      ])))
                                 (#eq? @type "%s")
                              )]],
                            receiver_type
                        )
                    )
                    local receiver_name
                    local has_methods = false
                    local has_ptr_receiver = false
                    for id, node, _ in methods_query:iter_captures(parent_of_type_decl_node, bufnr) do
                        has_methods = true

                        local captured_parent_node = node:parent()
                        if captured_parent_node and captured_parent_node:type() == "pointer_type" then
                            has_ptr_receiver = true
                        end
                        local capture_name = methods_query.captures[id]
                        if capture_name == "name" then
                            receiver_name = treesitter_get_node_text(node, bufnr)
                        end

                        if has_ptr_receiver and receiver_name then
                            break
                        end
                    end

                    if not has_methods then
                        -- Generate receiver name from its type.
                        -- Use pointer receiver by default. It's more common to use it.
                        return string.format("%s *%s", receiver_type:sub(1, 1):lower(), receiver_type)
                    end
                    if not receiver_name then
                        -- Receivers in methods don't have receiver names. Usually it happens for empty struct.
                        -- Return receiver without name.
                        if has_ptr_receiver then
                            -- If almost one pointer receiver exists, return pointer receiver too.
                            return string.format("*%s", receiver_type)
                        end
                        return receiver_type
                    end
                    if has_ptr_receiver then
                        -- If almost one pointer receiver exists, return pointer receiver too.
                        return string.format("%s *%s", receiver_name, receiver_type)
                    end
                    return string.format("%s %s", receiver_name, receiver_type)
                end
                local get_row_for_insertion = function(type_spec_node, receiver_type)
                    local type_decl_node = type_spec_node:parent()
                    local parent_of_type_decl_node = type_decl_node:parent() -- already checked.

                    -- Find last method by iterating over all.
                    local methods_query = treesitter_query_parse(
                        "go",
                        string.format(
                            [[(
                                (method_declaration
                                  receiver: (parameter_list
                                    (parameter_declaration
                                      type: [
                                        (pointer_type (type_identifier) @type)
                                        (type_identifier) @type
                                      ]))) @method
                                 (#eq? @type "%s")
                              )]],
                            receiver_type
                        )
                    )
                    local end_row_of_last_method
                    for id, node, _ in methods_query:iter_captures(parent_of_type_decl_node, bufnr) do
                        local capture_name = methods_query.captures[id]
                        if capture_name == "method" then
                            local end_row_of_node, _, _ = node:end_()
                            end_row_of_last_method = end_row_of_node
                        end
                    end

                    if end_row_of_last_method then
                        return end_row_of_last_method + 1
                    end
                    local end_row_of_type_spec, _, _ = type_decl_node:end_()
                    return end_row_of_type_spec + 1
                end
                local implement_interface = function(type_spec_node, receiver_type)
                    return {
                        title = "impl: implement interface",
                        action = function()
                            vim.ui.input({ prompt = "Enter interface name: " }, function(interface)
                                if not interface then
                                    return
                                end
                                if interface == "" then
                                    log:error("interface name cannot be empty")
                                    return
                                end

                                -- Save file before execution, because impl looks for type and its methods and
                                -- calculates diff between implemeted methods and interface methods and implements missing methods.
                                -- Do not trigger autocmds, they can format buffer and TS nodes will invalidate.
                                vim.cmd("noa w")
                                local receiver = get_receiver(type_spec_node, receiver_type)
                                local output = exec(receiver, interface)
                                if not output or output == "" then
                                    return
                                end

                                -- Trim, sometimes impl produces garbage newlines at the end.
                                output = vim.fn.trim(output)
                                local lines = vim.split(output, "\n")
                                table.insert(lines, 1, "")
                                local row_for_insertion = get_row_for_insertion(type_spec_node, receiver_type)
                                vim.api.nvim_buf_set_lines(bufnr, row_for_insertion, row_for_insertion, false, lines)
                            end)
                        end,
                    }
                end

                local tsnode
                if u.has_version("0.9.0") then
                    tsnode = vim.treesitter.get_node({ bufnr = bufnr, row = row - 1, col = col - 1 })
                else
                    tsnode = vim.treesitter.get_node_at_pos(bufnr, row - 1, col - 1, {})
                end
                if tsnode and tsnode:type() == "type_identifier" then
                    local type_spec_node = tsnode:parent()
                    if not type_spec_node or type_spec_node:type() ~= "type_spec" then
                        return
                    end
                    local receiver_type = treesitter_get_node_text(tsnode, bufnr)
                    if not receiver_type then
                        return
                    end

                    return { implement_interface(type_spec_node, receiver_type) }
                end
            end,
        }
    end,
})
