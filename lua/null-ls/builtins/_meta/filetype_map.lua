-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
-- stylua: ignore
return {
  asm = {
    formatting = { "asmfmt" }
  },
  beancount = {
    formatting = { "bean_format" }
  },
  c = {
    diagnostics = { "cppcheck", "gccdiag" },
    formatting = { "clang_format", "uncrustify" }
  },
  cmake = {
    formatting = { "cmake_format" }
  },
  cpp = {
    diagnostics = { "cppcheck", "gccdiag" },
    formatting = { "clang_format", "uncrustify" }
  },
  crystal = {
    formatting = { "crystal_format" }
  },
  cs = {
    formatting = { "clang_format", "uncrustify" }
  },
  css = {
    diagnostics = { "stylelint" },
    formatting = { "prettier", "prettierd", "prettier_d_slim", "stylelint" }
  },
  d = {
    formatting = { "dfmt" }
  },
  dart = {
    formatting = { "dart_format" }
  },
  django = {
    formatting = { "djhtml" }
  },
  dockerfile = {
    diagnostics = { "hadolint" }
  },
  elixir = {
    diagnostics = { "credo" },
    formatting = { "mix", "surface" }
  },
  elm = {
    formatting = { "elm_format" }
  },
  erlang = {
    formatting = { "erlfmt" }
  },
  fennel = {
    formatting = { "fnlfmt" }
  },
  fish = {
    formatting = { "fish_indent" }
  },
  fnl = {
    formatting = { "fnlfmt" }
  },
  fortran = {
    formatting = { "fprettify" }
  },
  go = {
    diagnostics = { "golangci_lint", "revive", "staticcheck" },
    formatting = { "gofmt", "gofumpt", "goimports", "golines" }
  },
  graphql = {
    formatting = { "prettier", "prettierd", "prettier_d_slim" }
  },
  haskell = {
    formatting = { "brittany" }
  },
  html = {
    formatting = { "prettier", "prettierd", "prettier_d_slim", "rustywind" }
  },
  htmldjango = {
    formatting = { "djhtml" }
  },
  java = {
    formatting = { "clang_format", "google_java_format", "uncrustify" }
  },
  javascript = {
    diagnostics = { "eslint", "eslint_d" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettierd", "prettier_d_slim", "rustywind" }
  },
  javascriptreact = {
    diagnostics = { "eslint", "eslint_d" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettierd", "prettier_d_slim", "rustywind" }
  },
  ["jinja.html"] = {
    formatting = { "djhtml" }
  },
  json = {
    formatting = { "fixjson", "json_tool", "prettier", "prettierd", "prettier_d_slim" }
  },
  less = {
    diagnostics = { "stylelint" },
    formatting = { "prettier", "prettierd", "prettier_d_slim", "stylelint" }
  },
  lua = {
    diagnostics = { "luacheck", "selene" },
    formatting = { "lua_format", "stylua" }
  },
  markdown = {
    diagnostics = { "markdownlint", "proselint", "vale", "write_good" },
    formatting = { "markdownlint", "prettier", "prettierd", "prettier_d_slim" },
    hover = { "dictionary" }
  },
  nginx = {
    formatting = { "nginx_beautifier" }
  },
  nix = {
    diagnostics = { "statix" },
    formatting = { "nixfmt" }
  },
  perl = {
    formatting = { "perltidy" }
  },
  php = {
    diagnostics = { "php", "phpcs", "phpstan", "psalm" },
    formatting = { "phpcbf", "phpcsfixer" }
  },
  prisma = {
    formatting = { "prismaFmt" }
  },
  python = {
    diagnostics = { "flake8", "mypy", "pylama", "pylint" },
    formatting = { "autopep8", "black", "isort", "reorder_python_imports", "yapf" }
  },
  qml = {
    diagnostics = { "qmllint" },
    formatting = { "qmlformat" }
  },
  r = {
    formatting = { "format_r", "styler" }
  },
  rmd = {
    formatting = { "format_r", "styler" }
  },
  ruby = {
    diagnostics = { "rubocop", "standardrb" },
    formatting = { "rubocop", "rufo", "standardrb" }
  },
  rust = {
    formatting = { "rustfmt" }
  },
  sass = {
    diagnostics = { "stylelint" },
    formatting = { "stylelint" }
  },
  scala = {
    formatting = { "scalafmt" }
  },
  scss = {
    diagnostics = { "stylelint" },
    formatting = { "prettier", "prettierd", "prettier_d_slim", "stylelint" }
  },
  sh = {
    diagnostics = { "shellcheck" },
    formatting = { "shellharden", "shfmt" }
  },
  sql = {
    formatting = { "sqlformat" }
  },
  surface = {
    formatting = { "surface" }
  },
  svelte = {
    formatting = { "rustywind" }
  },
  swift = {
    formatting = { "swiftformat" }
  },
  teal = {
    diagnostics = { "teal" }
  },
  terraform = {
    formatting = { "terraform_fmt" }
  },
  tex = {
    diagnostics = { "chktex", "proselint", "vale" }
  },
  text = {
    hover = { "dictionary" }
  },
  tf = {
    formatting = { "terraform_fmt" }
  },
  toml = {
    formatting = { "taplo" }
  },
  typescript = {
    diagnostics = { "eslint", "eslint_d", "tsc" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettierd", "prettier_d_slim", "rustywind" }
  },
  typescriptreact = {
    diagnostics = { "eslint", "eslint_d", "tsc" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettierd", "prettier_d_slim", "rustywind" }
  },
  vim = {
    diagnostics = { "vint" }
  },
  vue = {
    diagnostics = { "eslint", "eslint_d" },
    formatting = { "eslint", "eslint_d", "prettier", "prettierd", "prettier_d_slim", "rustywind" }
  },
  yaml = {
    diagnostics = { "ansiblelint", "yamllint" },
    formatting = { "prettier", "prettierd", "prettier_d_slim" }
  },
  zig = {
    formatting = { "zigfmt" }
  }
}
