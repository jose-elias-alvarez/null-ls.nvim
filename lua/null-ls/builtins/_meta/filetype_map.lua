-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
-- stylua: ignore
return {
  Jenkinsfile = {
    formatting = { "npm_groovy_lint" }
  },
  arduino = {
    formatting = { "astyle" }
  },
  asciidoc = {
    diagnostics = { "vale" }
  },
  asm = {
    formatting = { "asmfmt" }
  },
  bash = {
    formatting = { "beautysh" }
  },
  beancount = {
    formatting = { "bean_format" }
  },
  bib = {
    formatting = { "bibclean" }
  },
  blade = {
    formatting = { "blade_formatter" }
  },
  bzl = {
    diagnostics = { "buildifier" },
    formatting = { "buildifier" }
  },
  c = {
    diagnostics = { "clang_check", "cppcheck", "cpplint", "gccdiag" },
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
    formatting = { "cmake_format", "gersemi" }
  },
  cpp = {
    diagnostics = { "clang_check", "cppcheck", "cpplint", "gccdiag" },
    formatting = { "astyle", "clang_format", "uncrustify" }
  },
  crystal = {
    formatting = { "crystal_format" }
  },
  cs = {
    formatting = { "astyle", "clang_format", "csharpier", "uncrustify" }
  },
  csh = {
    formatting = { "beautysh" }
  },
  css = {
    diagnostics = { "stylelint" },
    formatting = { "prettier", "prettier_d_slim", "prettierd", "stylelint" }
  },
  cuda = {
    formatting = { "clang_format" }
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
  dosbatch = {
    hover = { "printenv" }
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
    diagnostics = { "commitlint", "gitlint" }
  },
  gitrebase = {
    code_actions = { "gitrebase" }
  },
  glsl = {
    diagnostics = { "glslc" }
  },
  go = {
    code_actions = { "refactoring" },
    diagnostics = { "golangci_lint", "revive", "semgrep", "staticcheck" },
    formatting = { "gofmt", "gofumpt", "goimports", "goimports_reviser", "golines" }
  },
  graphql = {
    formatting = { "prettier", "prettier_d_slim", "prettierd" }
  },
  groovy = {
    formatting = { "npm_groovy_lint" }
  },
  haml = {
    diagnostics = { "haml_lint" }
  },
  handlebars = {
    formatting = { "prettier", "prettier_d_slim", "prettierd" }
  },
  haskell = {
    formatting = { "brittany", "fourmolu", "stylish_haskell" }
  },
  hcl = {
    formatting = { "packer" }
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
    formatting = { "astyle", "clang_format", "google_java_format", "npm_groovy_lint", "uncrustify" }
  },
  javascript = {
    code_actions = { "eslint", "eslint_d", "refactoring", "xo" },
    diagnostics = { "eslint", "eslint_d", "jshint", "standardjs", "xo" },
    formatting = { "deno_fmt", "dprint", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_standard", "prettierd", "rome", "rustywind", "standardjs" }
  },
  javascriptreact = {
    code_actions = { "eslint", "eslint_d", "xo" },
    diagnostics = { "eslint", "eslint_d", "standardjs", "xo" },
    formatting = { "deno_fmt", "dprint", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_standard", "prettierd", "rustywind", "standardjs" }
  },
  ["jinja.html"] = {
    diagnostics = { "curlylint", "djlint" },
    formatting = { "djhtml", "djlint" }
  },
  json = {
    diagnostics = { "cfn_lint", "jsonlint", "spectral" },
    formatting = { "deno_fmt", "dprint", "fixjson", "jq", "json_tool", "prettier", "prettier_d_slim", "prettierd" }
  },
  jsonc = {
    formatting = { "deno_fmt", "prettier", "prettier_d_slim", "prettierd" }
  },
  just = {
    formatting = { "just" }
  },
  kotlin = {
    diagnostics = { "ktlint" },
    formatting = { "ktlint" }
  },
  ksh = {
    formatting = { "beautysh" }
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
    formatting = { "cbfmt", "deno_fmt", "dprint", "markdown_toc", "markdownlint", "mdformat", "ocdc", "prettier", "prettier_d_slim", "prettierd", "remark", "terrafmt" },
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
  org = {
    formatting = { "cbfmt" }
  },
  pascal = {
    formatting = { "ptop" }
  },
  perl = {
    formatting = { "perlimports", "perltidy" }
  },
  pgsql = {
    formatting = { "pg_format" }
  },
  php = {
    diagnostics = { "php", "phpcs", "phpmd", "phpstan", "psalm" },
    formatting = { "phpcbf", "phpcsfixer", "pint" }
  },
  prisma = {
    formatting = { "prismaFmt" }
  },
  proto = {
    diagnostics = { "buf", "protoc_gen_lint", "protolint" },
    formatting = { "buf", "protolint" }
  },
  ps1 = {
    hover = { "printenv" }
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
    diagnostics = { "flake8", "mypy", "pycodestyle", "pydocstyle", "pylama", "pylint", "pyproject_flake8", "semgrep", "vulture" },
    formatting = { "autopep8", "black", "blue", "isort", "reorder_python_imports", "usort", "yapf" }
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
  rego = {
    diagnostics = { "opacheck" }
  },
  rescript = {
    formatting = { "rescript" }
  },
  rmd = {
    formatting = { "format_r", "styler" }
  },
  roslyn = {
    formatting = { "dprint" }
  },
  rst = {
    diagnostics = { "rstcheck" }
  },
  ruby = {
    diagnostics = { "rubocop", "semgrep", "standardrb" },
    formatting = { "rubocop", "rufo", "standardrb" }
  },
  rust = {
    formatting = { "dprint", "rustfmt" }
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
    formatting = { "beautysh", "shellharden", "shfmt" },
    hover = { "printenv" }
  },
  solidity = {
    diagnostics = { "solhint" }
  },
  spec = {
    diagnostics = { "rpmspec" }
  },
  sql = {
    diagnostics = { "sqlfluff" },
    formatting = { "pg_format", "sql_formatter", "sqlfluff", "sqlformat" }
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
    formatting = { "dprint", "taplo" }
  },
  twig = {
    diagnostics = { "twigcs" }
  },
  typescript = {
    code_actions = { "eslint", "eslint_d", "refactoring", "xo" },
    diagnostics = { "eslint", "eslint_d", "semgrep", "tsc", "xo" },
    formatting = { "deno_fmt", "dprint", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rome", "rustywind" }
  },
  typescriptreact = {
    code_actions = { "eslint", "eslint_d", "xo" },
    diagnostics = { "eslint", "eslint_d", "semgrep", "tsc", "xo" },
    formatting = { "deno_fmt", "dprint", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettierd", "rustywind" }
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
    diagnostics = { "actionlint", "cfn_lint", "spectral", "yamllint" },
    formatting = { "prettier", "prettier_d_slim", "prettierd", "yamlfmt" }
  },
  ["yaml.ansible"] = {
    diagnostics = { "ansiblelint" }
  },
  zig = {
    formatting = { "zigfmt" }
  },
  zsh = {
    diagnostics = { "zsh" },
    formatting = { "beautysh" }
  }
}
