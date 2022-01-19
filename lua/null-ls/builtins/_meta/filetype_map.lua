-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
-- stylua: ignore
return {
  asm = {
    formatting = { "asmfmt" }
  },
  beancount = {
    formatting = { "bean_format" }
  },
  bzl = {
    formatting = { "buildifier" }
  },
  c = {
    diagnostics = { "cppcheck", "gccdiag" },
    formatting = { "clang_format", "uncrustify" }
  },
  cabal = {
    formatting = { "cabal_fmt" }
  },
  clj = {
    formatting = { "joker" }
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
    formatting = { "prettier", "prettier_d_slim", "prettierd", "stylelint" }
  },
  cue = {
    diagnostics = { "cue_fmt" },
    formatting = { "cue_fmt" }
  },
  d = {
    formatting = { "dfmt" }
  },
  dart = {
    formatting = { "dart_format" }
  },
  delphi = {
    formatting = { "ptop" }
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
  gitcommit = {
    diagnostics = { "gitlint" }
  },
  go = {
    diagnostics = { "golangci_lint", "revive", "staticcheck" },
    formatting = { "gofmt", "gofumpt", "goimports", "golines" }
  },
  graphql = {
    formatting = { "prettier", "prettier_d_slim", "prettierd" }
  },
  haskell = {
    formatting = { "brittany", "fourmolu" }
  },
  html = {
    formatting = { "prettier", "prettier_d_slim", "prettierd", "rustywind" }
  },
  htmldjango = {
    formatting = { "djhtml" }
  },
  java = {
    formatting = { "clang_format", "google_java_format", "uncrustify" }
  },
  javascript = {
    diagnostics = { "eslint", "eslint_d", "standardjs" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_standard", "prettierd", "rustywind" }
  },
  javascriptreact = {
    diagnostics = { "eslint", "eslint_d", "standardjs" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_standard", "prettierd", "rustywind" }
  },
  ["jinja.html"] = {
    formatting = { "djhtml" }
  },
  json = {
    diagnostics = { "jsonlint" },
    formatting = { "fixjson", "json_tool", "prettier", "prettier_d_slim", "prettierd" }
  },
  less = {
    diagnostics = { "stylelint" },
    formatting = { "prettier", "prettier_d_slim", "prettierd", "stylelint" }
  },
  lua = {
    diagnostics = { "luacheck", "selene" },
    formatting = { "lua_format", "stylua" }
  },
  markdown = {
    diagnostics = { "alex", "markdownlint", "mdl", "proselint", "vale", "write_good" },
    formatting = { "markdownlint", "prettier", "prettier_d_slim", "prettierd" },
    hover = { "dictionary" }
  },
  nginx = {
    formatting = { "nginx_beautifier" }
  },
  nim = {
    formatting = { "nimpretty" }
  },
  nix = {
    diagnostics = { "statix" },
    formatting = { "nixfmt" }
  },
  pascal = {
    formatting = { "ptop" }
  },
  perl = {
    formatting = { "perltidy" }
  },
  pgsql = {
    formatting = { "pg_format" }
  },
  php = {
    diagnostics = { "php", "phpcs", "phpstan", "psalm" },
    formatting = { "phpcbf", "phpcsfixer" }
  },
  prisma = {
    formatting = { "prismaFmt" }
  },
  proto = {
    diagnostics = { "protoc_gen_lint", "protolint" },
    formatting = { "protolint" }
  },
  python = {
    diagnostics = { "flake8", "mypy", "pylama", "pylint", "vulture" },
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
    formatting = { "prettier", "prettier_d_slim", "prettierd", "stylelint" }
  },
  sh = {
    diagnostics = { "shellcheck" },
    formatting = { "shellharden", "shfmt" }
  },
  sql = {
    formatting = { "pg_format", "sqlformat" }
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
    diagnostics = { "chktex", "proselint", "vale" },
    formatting = { "latexindent" }
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
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" }
  },
  typescriptreact = {
    diagnostics = { "eslint", "eslint_d", "tsc" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" }
  },
  vim = {
    diagnostics = { "vint" }
  },
  vue = {
    diagnostics = { "eslint", "eslint_d" },
    formatting = { "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" }
  },
  yaml = {
    diagnostics = { "ansiblelint", "yamllint" },
    formatting = { "prettier", "prettier_d_slim", "prettierd" }
  },
  zig = {
    formatting = { "zigfmt" }
  }
}
