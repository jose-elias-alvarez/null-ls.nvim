local h = require("null-ls.helpers")
local log = require("null-ls.logger")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    name = "gotests",
    meta = {
        url = "https://github.com/cweill/gotests",
        description = "Go tool to generate tests",
        notes = { "Requires installing the Go tree-sitter parser." },
    },
    method = CODE_ACTION,
    filetypes = { "go" },
    can_run = function()
        return require("null-ls.utils").is_executable("gotests")
    end,
    generator_opts = {
        command = "gotests",
        args = { "-w" },
    },
    factory = function(opts)
        return {
            fn = function(params)
                local bufnr = params.bufnr
                local bufname = params.bufname
                local row = params.range.row
                local col = params.range.col
                print(vim.inspect(vim.fn.expand("%:p:h")))

                local exec = function(cmd_opts)
                    print(vim.inspect(cmd_opts))
                    local cmd = table.concat(cmd_opts, " ")
                    local output = vim.fn.system(cmd)
                    if vim.api.nvim_get_vvar("shell_error") == 0 then
                        vim.fn.execute(":e " .. bufname) -- reload the file
                    else
                        log:error(output) -- print the error message
                    end
                end
                local add_function_test = function(fn_name)
                    return {
                        title = "gtests: add test for function: " .. fn_name,
                        action = function()
                            local cmd_opts = vim.list_extend({ opts.command }, opts.args or {})
                            vim.list_extend(cmd_opts, { "--only", fn_name })
                            vim.list_extend(cmd_opts, { bufname })
                            return exec(cmd_opts)
                        end,
                    }
                end
                local add_package_test = function(pkg_name)
                    return {
                        title = "gotests: add tests for package: " .. pkg_name,
                        action = function()
                            local cmd_opts = vim.list_extend({ opts.command }, opts.args or {})
                            vim.list_extend(cmd_opts, { "--all" })
                            vim.list_extend(cmd_opts, { vim.fn.expand("%:p:h") })
                            return exec(cmd_opts)
                        end,
                    }
                end

                -- Main
                local tsnode = vim.treesitter.get_node_at_pos(bufnr, row - 1, col - 1, {})
                local actions = {}
                local package_name
                local function_name

                -- Ops on function name
                if (tsnode:type()) == "identifier" then
                    function_name = vim.treesitter.query.get_node_text(tsnode, 0)
                    if function_name == nil then
                        return
                    end

                    table.insert(actions, add_function_test(function_name))
                end
                if (tsnode:type()) == "package_clause" then
                    local tscnode = tsnode:child(1)
                    if tscnode ~= nil and (tscnode:type() == "package_identifier") then
                        package_name = vim.treesitter.query.get_node_text(tscnode, 0)
                    end
                    table.insert(actions, add_package_test(package_name))
                end
                return actions
            end,
        }
    end,
})
