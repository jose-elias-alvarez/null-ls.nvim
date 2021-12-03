-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
-- stylua: ignore
return {
  ["*"] = {
    formatters = { "trim_whitespace", "trim_newlines", "codespell" },
    linters = { "misspell", "codespell" }
  },
  asm = {
    formatters = { "asmfmt" }
  },
  beancount = {
    formatters = { "bean_format" }
  },
  c = {
    formatters = { "uncrustify", "clang_format" },
    linters = { "cppcheck" }
  },
  cmake = {
    formatters = { "cmake_format" }
  },
  cpp = {
    formatters = { "uncrustify", "clang_format" },
    linters = { "cppcheck" }
  },
  crystal = {
    formatters = { "crystal_format" }
  },
  cs = {
    formatters = { "uncrustify", "clang_format" }
  },
  css = {
    formatters = { "prettier", "prettier_d_slim", "stylelint" },
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
    linters = { "revive", "staticcheck", "golangci_lint" }
  },
  graphql = {
    formatters = { "prettier", "prettier_d_slim" }
  },
  html = {
    formatters = { "prettier", "prettier_d_slim", "rustywind" }
  },
  java = {
    formatters = { "google_java_format", "uncrustify", "clang_format" }
  },
  javascript = {
    formatters = { "prettier", "prettier_d_slim", "rustywind", "eslint", "deno_fmt", "eslint_d" },
    linters = { "eslint", "eslint_d" }
  },
  javascriptreact = {
    formatters = { "prettier", "prettier_d_slim", "rustywind", "eslint", "deno_fmt", "eslint_d" },
    linters = { "eslint", "eslint_d" }
  },
  json = {
    formatters = { "json_tool", "prettier", "prettier_d_slim", "fixjson" }
  },
  less = {
    formatters = { "prettier", "prettier_d_slim", "stylelint" },
    linters = { "stylelint" }
  },
  lua = {
    formatters = { "lua_format", "stylua" },
    linters = { "selene", "luacheck" }
  },
  markdown = {
    formatters = { "prettier", "prettier_d_slim", "markdownlint" },
    linters = { "proselint", "vale", "write_good", "cspell", "markdownlint" }
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
    formatters = { "isort", "yapf", "reorder_python_imports", "autopep8", "black" },
    linters = { "mypy", "pylama", "pylint", "flake8" }
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
    formatters = { "rufo", "standardrb", "rubocop" },
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
    formatters = { "prettier", "prettier_d_slim", "stylelint" },
    linters = { "stylelint" }
  },
  sh = {
    formatters = { "shfmt", "shellharden" },
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
    linters = { "proselint", "vale", "chktex" }
  },
  tf = {
    formatters = { "terraform_fmt" }
  },
  toml = {
    formatters = { "taplo" }
  },
  typescript = {
    formatters = { "prettier", "prettier_d_slim", "rustywind", "eslint", "deno_fmt", "eslint_d" },
    linters = { "eslint", "eslint_d" }
  },
  typescriptreact = {
    formatters = { "prettier", "prettier_d_slim", "rustywind", "eslint", "deno_fmt", "eslint_d" },
    linters = { "eslint", "eslint_d" }
  },
  vim = {
    linters = { "vint" }
  },
  vue = {
    formatters = { "prettier", "prettier_d_slim", "rustywind", "eslint", "eslint_d" },
    linters = { "eslint", "eslint_d" }
  },
  yaml = {
    formatters = { "prettier", "prettier_d_slim" },
    linters = { "yamllint" }
  },
  zig = {
    formatters = { "zigfmt" }
  }
}
