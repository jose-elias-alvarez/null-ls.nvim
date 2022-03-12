-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
-- stylua: ignore
return {
  arduino = {
    formatting = { "astyle" }
  },
  asciidoc = {
    diagnostics = { "vale" }
  },
  asm = {
    formatting = { "asmfmt" }
  },
  beancount = {
    formatting = { "bean_format" }
  },
  bzl = {
    diagnostics = { "buildifier" },
    formatting = { "buildifier" }
  },
  c = {
    diagnostics = { "cppcheck", "gccdiag" },
    formatting = { "astyle", "clang_format", "uncrustify" }
  },
  cabal = {
    formatting = { "cabal_fmt" }
  },
  clj = {
    formatting = { "joker" }
  },
  clojure = {
    formatting = { "cljstyle" }
  },
  cmake = {
    formatting = { "cmake_format" }
  },
  cpp = {
    diagnostics = { "cppcheck", "gccdiag" },
    formatting = { "astyle", "clang_format", "uncrustify" }
  },
  crystal = {
    formatting = { "crystal_format" }
  },
  cs = {
    formatting = { "astyle", "clang_format", "uncrustify" }
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
    diagnostics = { "djlint" },
    formatting = { "djhtml", "djlint" }
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
  epuppet = {
    diagnostics = { "puppet_lint" },
    formatting = { "puppet_lint" }
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
  gitrebase = {
    code_actions = { "gitrebase" }
  },
  go = {
    code_actions = { "refactoring" },
    diagnostics = { "golangci_lint", "revive", "staticcheck" },
    formatting = { "gofmt", "gofumpt", "goimports", "golines" }
  },
  graphql = {
    formatting = { "prettier", "prettier_d_slim", "prettierd" }
  },
  haml = {
    diagnostics = { "haml_lint" }
  },
  handlebars = {
    formatting = { "prettier", "prettier_d_slim", "prettierd" }
  },
  haskell = {
    formatting = { "brittany", "fourmolu" }
  },
  html = {
    formatting = { "prettier", "prettier_d_slim", "prettierd", "rustywind" }
  },
  htmldjango = {
    diagnostics = { "curlylint", "djlint" },
    formatting = { "djhtml", "djlint" }
  },
  java = {
    formatting = { "astyle", "clang_format", "google_java_format", "uncrustify" }
  },
  javascript = {
    code_actions = { "eslint", "eslint_d", "refactoring", "xo" },
    diagnostics = { "eslint", "eslint_d", "standardjs", "xo" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_standard", "prettierd", "rustywind", "standardjs" }
  },
  javascriptreact = {
    code_actions = { "eslint", "eslint_d", "xo" },
    diagnostics = { "eslint", "eslint_d", "standardjs", "xo" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_standard", "prettierd", "rustywind", "standardjs" }
  },
  ["jinja.html"] = {
    diagnostics = { "curlylint", "djlint" },
    formatting = { "djhtml", "djlint" }
  },
  json = {
    diagnostics = { "jsonlint" },
    formatting = { "fixjson", "json_tool", "prettier", "prettier_d_slim", "prettierd" }
  },
  jsonc = {
    formatting = { "prettier", "prettier_d_slim", "prettierd" }
  },
  kotlin = {
    diagnostics = { "ktlint" },
    formatting = { "ktlint" }
  },
  less = {
    diagnostics = { "stylelint" },
    formatting = { "prettier", "prettier_d_slim", "prettierd", "stylelint" }
  },
  lua = {
    code_actions = { "refactoring" },
    diagnostics = { "luacheck", "selene" },
    formatting = { "lua_format", "stylua" }
  },
  make = {
    diagnostics = { "checkmake" }
  },
  markdown = {
    code_actions = { "proselint" },
    diagnostics = { "alex", "markdownlint", "mdl", "proselint", "vale", "write_good" },
    formatting = { "markdownlint", "prettier", "prettier_d_slim", "prettierd", "remark", "terrafmt" },
    hover = { "dictionary" }
  },
  nginx = {
    formatting = { "nginx_beautifier" }
  },
  nim = {
    formatting = { "nimpretty" }
  },
  nix = {
    code_actions = { "statix" },
    diagnostics = { "deadnix", "statix" },
    formatting = { "nixfmt", "nixpkgs_fmt" }
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
    diagnostics = { "php", "phpcs", "phpmd", "phpstan", "psalm" },
    formatting = { "phpcbf", "phpcsfixer" }
  },
  prisma = {
    formatting = { "prismaFmt" }
  },
  proto = {
    diagnostics = { "protoc_gen_lint", "protolint" },
    formatting = { "protolint" }
  },
  pug = {
    diagnostics = { "puglint" }
  },
  puppet = {
    diagnostics = { "puppet_lint" },
    formatting = { "puppet_lint" }
  },
  python = {
    code_actions = { "refactoring" },
    diagnostics = { "flake8", "mypy", "pydocstyle", "pylama", "pylint", "pyproject_flake8", "vulture" },
    formatting = { "autopep8", "black", "isort", "reorder_python_imports", "yapf" }
  },
  qml = {
    diagnostics = { "qmllint" },
    formatting = { "qmlformat" }
  },
  r = {
    formatting = { "format_r", "styler" }
  },
  racket = {
    formatting = { "raco_fmt" }
  },
  rescript = {
    formatting = { "rescript" }
  },
  rmd = {
    formatting = { "format_r", "styler" }
  },
  rst = {
    diagnostics = { "rstcheck" }
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
    code_actions = { "shellcheck" },
    diagnostics = { "shellcheck" },
    formatting = { "shellharden", "shfmt" }
  },
  spec = {
    diagnostics = { "rpmspec" }
  },
  sql = {
    formatting = { "pg_format", "sqlformat" }
  },
  stylus = {
    diagnostics = { "stylint" }
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
    code_actions = { "proselint" },
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
    code_actions = { "eslint", "eslint_d", "refactoring", "xo" },
    diagnostics = { "eslint", "eslint_d", "tsc", "xo" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" }
  },
  typescriptreact = {
    code_actions = { "eslint", "eslint_d", "xo" },
    diagnostics = { "eslint", "eslint_d", "tsc", "xo" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" }
  },
  vim = {
    diagnostics = { "vint" }
  },
  vue = {
    code_actions = { "eslint", "eslint_d" },
    diagnostics = { "eslint", "eslint_d" },
    formatting = { "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" }
  },
  xml = {
    formatting = { "xmllint" }
  },
  yaml = {
    diagnostics = { "actionlint", "yamllint" },
    formatting = { "prettier", "prettier_d_slim", "prettierd" }
  },
  ["yaml.ansible"] = {
    diagnostics = { "ansiblelint" }
  },
  zig = {
    formatting = { "zigfmt" }
  },
  zsh = {
    diagnostics = { "zsh" }
  }
}
