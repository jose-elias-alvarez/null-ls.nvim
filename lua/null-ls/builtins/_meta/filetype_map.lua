-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
-- stylua: ignore
return {
  asm = {
    formatters = { "asmfmt" }
  },
  beancount = {
    formatters = { "bean_format" }
  },
  c = {
    formatters = { "clang_format", "uncrustify" },
    linters = { "cppcheck", "gccdiag" }
  },
  cmake = {
    formatters = { "cmake_format" }
  },
  cpp = {
    formatters = { "clang_format", "uncrustify" },
    linters = { "cppcheck", "gccdiag" }
  },
  crystal = {
    formatters = { "crystal_format" }
  },
  cs = {
    formatters = { "clang_format", "uncrustify" }
  },
  css = {
    formatters = { "prettier", "prettier_d_slim", "prettierd", "stylelint" },
    linters = { "stylelint" }
  },
  d = {
    formatters = { "dfmt" }
  },
  dart = {
    formatters = { "dart_format" }
  },
  dockerfile = {
    linters = { "hadolint" }
  },
  elixir = {
    formatters = { "mix", "surface" },
    linters = { "credo" }
  },
  elm = {
    formatters = { "elm_format" }
  },
  erlang = {
    formatters = { "erlfmt" }
  },
  fennel = {
    formatters = { "fnlfmt" }
  },
  fish = {
    formatters = { "fish_indent" }
  },
  fnl = {
    formatters = { "fnlfmt" }
  },
  fortran = {
    formatters = { "fprettify" }
  },
  go = {
    formatters = { "gofmt", "gofumpt", "goimports", "golines" },
    linters = { "golangci_lint" }
  },
  graphql = {
    formatters = { "prettier", "prettier_d_slim", "prettierd" }
  },
  html = {
    formatters = { "prettier", "prettier_d_slim", "prettierd", "rustywind" }
  },
  java = {
    formatters = { "clang_format", "google_java_format", "uncrustify" }
  },
  javascript = {
    formatters = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" },
    linters = { "eslint", "eslint_d" }
  },
  javascriptreact = {
    formatters = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" },
    linters = { "eslint", "eslint_d" }
  },
  json = {
    formatters = { "fixjson", "json_tool", "prettier", "prettier_d_slim", "prettierd" }
  },
  less = {
    formatters = { "prettier", "prettier_d_slim", "prettierd", "stylelint" },
    linters = { "stylelint" }
  },
  lua = {
    formatters = { "lua_format", "stylua" },
    linters = { "luacheck", "selene" }
  },
  markdown = {
    formatters = { "markdownlint", "prettier", "prettier_d_slim", "prettierd" },
    linters = { "cspell", "markdownlint", "proselint", "vale", "write_good" }
  },
  nginx = {
    formatters = { "nginx_beautifier" }
  },
  nix = {
    formatters = { "nixfmt" },
    linters = { "statix" }
  },
  perl = {
    formatters = { "perltidy" }
  },
  php = {
    formatters = { "phpcbf", "phpcsfixer" },
    linters = { "phpcs", "phpstan", "psalm" }
  },
  prisma = {
    formatters = { "prismaFmt" }
  },
  python = {
    formatters = { "autopep8", "black", "isort", "reorder_python_imports", "yapf" },
    linters = { "flake8", "mypy", "pylama", "pylint" }
  },
  qml = {
    formatters = { "qmlformat" },
    linters = { "qmllint" }
  },
  r = {
    formatters = { "format_r", "styler" }
  },
  rmd = {
    formatters = { "format_r", "styler" }
  },
  ruby = {
    formatters = { "rubocop", "rufo", "standardrb" },
    linters = { "rubocop", "standardrb" }
  },
  rust = {
    formatters = { "rustfmt" }
  },
  sass = {
    formatters = { "stylelint" },
    linters = { "stylelint" }
  },
  scala = {
    formatters = { "scalafmt" }
  },
  scss = {
    formatters = { "prettier", "prettier_d_slim", "prettierd", "stylelint" },
    linters = { "stylelint" }
  },
  sh = {
    formatters = { "shellharden", "shfmt" },
    linters = { "shellcheck" }
  },
  sql = {
    formatters = { "sqlformat" }
  },
  surface = {
    formatters = { "surface" }
  },
  svelte = {
    formatters = { "rustywind" }
  },
  swift = {
    formatters = { "swiftformat" }
  },
  teal = {
    linters = { "teal" }
  },
  terraform = {
    formatters = { "terraform_fmt" }
  },
  tex = {
    linters = { "chktex", "proselint", "vale" }
  },
  tf = {
    formatters = { "terraform_fmt" }
  },
  toml = {
    formatters = { "taplo" }
  },
  typescript = {
    formatters = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" },
    linters = { "eslint", "eslint_d", "tsc" }
  },
  typescriptreact = {
    formatters = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" },
    linters = { "eslint", "eslint_d", "tsc" }
  },
  vim = {
    linters = { "vint" }
  },
  vue = {
    formatters = { "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" },
    linters = { "eslint", "eslint_d" }
  },
  yaml = {
    formatters = { "prettier", "prettier_d_slim", "prettierd" },
    linters = { "ansiblelint", "yamllint" }
  },
  zig = {
    formatters = { "zigfmt" }
  }
}