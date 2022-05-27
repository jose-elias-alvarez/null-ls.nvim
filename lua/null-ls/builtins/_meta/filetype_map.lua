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
  bib = {
    formatting = { "bibclean" }
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
    diagnostics = { "clj_kondo" },
    formatting = { "cljstyle", "zprint" }
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
  eruby = {
    diagnostics = { "erb_lint" },
    formatting = { "erb_lint" }
  },
  fennel = {
    formatting = { "fnlfmt" }
  },
  fish = {
    diagnostics = { "fish" },
    formatting = { "fish_indent" }
  },
  fnl = {
    formatting = { "fnlfmt" }
  },
  fortran = {
    formatting = { "fprettify" }
  },
  gd = {
    formatting = { "gdformat" }
  },
  gdscript = {
    diagnostics = { "gdlint" },
    formatting = { "gdformat" }
  },
  gdscript3 = {
    formatting = { "gdformat" }
  },
  gitcommit = {
    diagnostics = { "gitlint" }
  },
  gitrebase = {
    code_actions = { "gitrebase" }
  },
  go = {
    code_actions = { "refactoring" },
    diagnostics = { "golangci_lint", "revive", "semgrep", "staticcheck" },
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
    diagnostics = { "tidy" },
    formatting = { "prettier", "prettier_d_slim", "prettierd", "rustywind", "tidy" }
  },
  htmldjango = {
    diagnostics = { "curlylint", "djlint" },
    formatting = { "djhtml", "djlint" }
  },
  java = {
    diagnostics = { "semgrep" },
    formatting = { "astyle", "clang_format", "google_java_format", "uncrustify" }
  },
  javascript = {
    code_actions = { "eslint", "eslint_d", "refactoring", "xo" },
    diagnostics = { "eslint", "eslint_d", "standardjs", "xo" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_standard", "prettierd", "rome", "rustywind", "standardjs" }
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
    formatting = { "fixjson", "jq", "json_tool", "prettier", "prettier_d_slim", "prettierd" }
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
    formatting = { "markdownlint", "mdformat", "prettier", "prettier_d_slim", "prettierd", "remark", "terrafmt" },
    hover = { "dictionary" }
  },
  matlab = {
    diagnostics = { "mlint" }
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
    formatting = { "alejandra", "nixfmt", "nixpkgs_fmt" }
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
    diagnostics = { "buf", "protoc_gen_lint", "protolint" },
    formatting = { "buf", "protolint" }
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
    diagnostics = { "flake8", "mypy", "pydocstyle", "pylama", "pylint", "pyproject_flake8", "semgrep", "vulture" },
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
    diagnostics = { "rubocop", "semgrep", "standardrb" },
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
  solidity = {
    diagnostics = { "solhint" }
  },
  spec = {
    diagnostics = { "rpmspec" }
  },
  sql = {
    diagnostics = { "sqlfluff" },
    formatting = { "pg_format", "sqlfluff", "sqlformat" }
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
  systemverilog = {
    formatting = { "verible_verilog_format" }
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
  twig = {
    diagnostics = { "twigcs" }
  },
  typescript = {
    code_actions = { "eslint", "eslint_d", "refactoring", "xo" },
    diagnostics = { "eslint", "eslint_d", "semgrep", "tsc", "xo" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rome", "rustywind" }
  },
  typescriptreact = {
    code_actions = { "eslint", "eslint_d", "xo" },
    diagnostics = { "eslint", "eslint_d", "semgrep", "tsc", "xo" },
    formatting = { "deno_fmt", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" }
  },
  verilog = {
    formatting = { "verible_verilog_format" }
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
    diagnostics = { "tidy" },
    formatting = { "tidy", "xmllint" }
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
