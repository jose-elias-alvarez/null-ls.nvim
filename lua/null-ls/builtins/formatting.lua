local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING
local RANGE_FORMATTING = methods.internal.RANGE_FORMATTING

local M = {}

M.asmfmt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "asm" },
    generator_opts = {
        command = "asmfmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.bean_format = h.make_builtin({
    method = FORMATTING,
    filetypes = { "beancount" },
    generator_opts = {
        command = "bean-format",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.black = h.make_builtin({
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "black",
        args = {
            "--quiet",
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.clang_format = h.make_builtin({
    method = FORMATTING,
    filetypes = { "c", "cpp", "cs", "java" },
    generator_opts = {
        command = "clang-format",
        args = { "-assume-filename", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.cmake_format = h.make_builtin({
    method = FORMATTING,
    filetypes = { "cmake" },
    generator_opts = {
        command = "cmake-format",
        args = { "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.crystal_format = h.make_builtin({
    method = FORMATTING,
    filetypes = { "crystal" },
    generator_opts = {
        command = "crystal",
        args = { "tool", "format" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.dfmt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "d" },
    generator_opts = {
        command = "dfmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.dart_format = h.make_builtin({
    method = FORMATTING,
    filetypes = { "dart" },
    generator_opts = {
        command = "dart",
        args = { "format" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.deno_fmt = h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
    },
    generator_opts = {
        command = "deno",
        args = { "fmt", "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.elm_format = h.make_builtin({
    method = FORMATTING,
    filetypes = { "elm" },
    generator_opts = {
        command = "elm-format",
        args = { "--stdin" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.eslint = h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
    },
    factory = h.generator_factory,
    generator_opts = {
        command = "eslint",
        args = { "--fix-dry-run", "--format", "json", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
        format = "json",
        on_output = function(params)
            local parsed = params.output[1]
            return parsed
                and parsed.output
                and {
                    {
                        row = 1,
                        col = 1,
                        end_row = #vim.split(parsed.output, "\n") + 1,
                        end_col = 1,
                        text = parsed.output,
                    },
                }
        end,
    },
})

M.eslint_d = h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
    },
    generator_opts = {
        command = "eslint_d",
        args = { "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.erlfmt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "erlang" },
    generator_opts = {
        command = "erlfmt",
        args = { "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.fish_indent = h.make_builtin({
    method = FORMATTING,
    filetypes = { "fish" },
    generator_opts = {
        command = "fish_indent",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.fixjson = h.make_builtin({
    method = FORMATTING,
    filetypes = { "json" },
    generator_opts = {
        command = "fixjson",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.fnlfmt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "fennel", "fnl" },
    generator_opts = {
        command = "fnlfmt",
        args = { "--fix" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.format_r = h.make_builtin({
    method = FORMATTING,
    filetypes = { "r", "rmd" },
    generator_opts = {
        command = "R",
        args = h.range_formatting_args_factory({
            "--slave",
            "--no-restore",
            "--no-save",
            "-e",
            'formatR::tidy_source(source="stdin")',
        }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.fprettify = h.make_builtin({
    method = FORMATTING,
    filetypes = { "fortran" },
    generator_opts = {
        command = "fprettify",
        args = {
            "--silent",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.golines = h.make_builtin({
    method = FORMATTING,
    filetypes = { "go" },
    generator_opts = {
        command = "golines",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.goimports = h.make_builtin({
    method = FORMATTING,
    filetypes = { "go" },
    generator_opts = {
        command = "goimports",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.gofmt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "go" },
    generator_opts = {
        command = "gofmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.gofumpt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "go" },
    generator_opts = {
        command = "gofumpt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.isort = h.make_builtin({
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "isort",
        args = {
            "--stdout",
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.json_tool = h.make_builtin({
    method = FORMATTING,
    filetypes = { "json" },
    generator_opts = {
        command = "python",
        args = { "-m", "json.tool" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.lua_format = h.make_builtin({
    method = FORMATTING,
    filetypes = { "lua" },
    generator_opts = {
        command = "lua-format",
        args = { "-i" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.mix = h.make_builtin({
    method = FORMATTING,
    filetypes = { "elixir" },
    generator_opts = {
        command = "mix",
        args = { "format", "-" },
        format = "raw",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.surface = h.make_builtin({
    method = FORMATTING,
    filetypes = { "elixir", "surface" },
    generator_opts = {
        command = "mix",
        args = { "surface.format", "-" },
        format = "raw",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.nginx_beautifier = h.make_builtin({
    method = FORMATTING,
    filetypes = { "nginx" },
    generator_opts = {
        command = "nginxbeautifier",
        args = { "-i" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.nixfmt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "nix" },
    generator_opts = {
        command = "nixfmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.perltidy = h.make_builtin({
    method = FORMATTING,
    filetypes = { "perl" },
    generator_opts = {
        command = "perltidy",
        args = { "-q" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.phpcbf = h.make_builtin({
    method = FORMATTING,
    filetypes = { "php" },
    generator_opts = {
        command = "phpcbf",
        args = {
            -- silence status messages during processing
            "-q",
            -- process stdin
            "-",
        },
        to_stdin = true,
        check_exit_code = function(code)
            -- phpcbf return a 1 or 2 exit code if it detects warnings or errors
            return code <= 2
        end,
    },
    factory = h.formatter_factory,
})

M.prettier = h.make_builtin({
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
        "css",
        "scss",
        "html",
        "json",
        "yaml",
        "markdown",
    },
    generator_opts = {
        command = "prettier",
        args = h.range_formatting_args_factory({ "--stdin-filepath", "$FILENAME" }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.prettierd = h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
        "css",
        "scss",
        "html",
        "json",
        "yaml",
        "markdown",
    },
    generator_opts = {
        command = "prettierd",
        args = { "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.prettier_d_slim = h.make_builtin({
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
    },
    generator_opts = {
        command = "prettier_d_slim",
        args = h.range_formatting_args_factory({ "--stdin", "--stdin-filepath", "$FILENAME" }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.prismaFmt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "prisma" },
    generator_opts = {
        command = "prisma-fmt",
        args = { "format", "-i", "$FILENAME" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.rufo = h.make_builtin({
    method = FORMATTING,
    filetypes = { "ruby" },
    generator_opts = {
        command = "rufo",
        args = { "-x" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.rubocop = h.make_builtin({
    method = FORMATTING,
    filetypes = { "ruby" },
    generator_opts = {
        command = "rubocop",
        args = {
            "--auto-correct",
            "--stdin",
            "$FILENAME",
            "2>/dev/null",
            "|",
            "awk 'f; /^====================$/{f=1}'",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.rustfmt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "rust" },
    generator_opts = {
        command = "rustfmt",
        args = { "--emit=stdout" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.sqlformat = h.make_builtin({
    method = FORMATTING,
    filetypes = { "sql" },
    generator_opts = {
        command = "sqlformat",
        args = { "-" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.scalafmt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "scala" },
    generator_opts = {
        command = "scalafmt",
        args = { "--stdin" },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.shfmt = h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "sh",
    },
    generator_opts = {
        command = "shfmt",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.shellharden = h.make_builtin({
    method = FORMATTING,
    filetypes = {
        "sh",
    },
    generator_opts = {
        command = "shellharden",
        args = { "--transform", "$FILENAME" },
        to_stdin = false,
    },
    factory = h.formatter_factory,
})

M.styler = h.make_builtin({
    method = FORMATTING,
    filetypes = { "r", "rmd" },
    generator_opts = {
        command = "R",
        args = h.range_formatting_args_factory({
            "--slave",
            "--no-restore",
            "--no-save",
            "-e",
            'con=file("stdin");output=styler::style_text(readLines(con));close(con);print(output, colored=FALSE)',
        }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.stylua = h.make_builtin({
    method = { FORMATTING, RANGE_FORMATTING },
    filetypes = { "lua" },
    generator_opts = {
        command = "stylua",
        args = h.range_formatting_args_factory({ "--search-parent-directories", "--stdin-filepath", "$FILENAME", "-" }),
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.swiftformat = h.make_builtin({
    method = FORMATTING,
    filetypes = { "swift" },
    generator_opts = {
        command = "swiftformat",
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.terraform_fmt = h.make_builtin({
    method = FORMATTING,
    filetypes = { "terraform", "tf" },
    generator_opts = {
        command = "terraform",
        args = {
            "fmt",
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.trim_whitespace = h.make_builtin({
    method = FORMATTING,
    generator_opts = {
        command = "awk",
        args = { '{ sub(/[ \t]+$/, ""); print }' },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.uncrustify = h.make_builtin({
    method = FORMATTING,
    filetypes = { "c", "cpp", "cs", "java" },
    generator_opts = {
        command = "uncrustify",
        args = function(params)
            local format_type = "-l " .. params.ft:upper()
            return { "-q", format_type }
        end,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.yapf = h.make_builtin({
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "yapf",
        args = {
            "--quiet",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.autopep8 = h.make_builtin({
    method = FORMATTING,
    filetypes = { "python" },
    generator_opts = {
        command = "autopep8",
        args = {
            "-",
        },
        to_stdin = true,
    },
    factory = h.formatter_factory,
})

M.phpcsfixer = h.make_builtin({
    method = FORMATTING,
    filetypes = { "php" },
    generator_opts = {
        command = "php-cs-fixer",
        args = {
            "--no-interaction",
            "--quiet",
            "fix",
            "$FILENAME",
        },
        to_stdin = false,
        to_temp_file = true,
    },
    factory = h.formatter_factory,
})

return M
