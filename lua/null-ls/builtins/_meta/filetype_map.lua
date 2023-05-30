-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
-- stylua: ignore
return {
  Jenkinsfile = {
    diagnostics = { "npm_groovy_lint" },
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
  brs = {
    diagnostics = { "bslint" },
    formatting = { "bsfmt" }
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
    diagnostics = { "cmake_lint" },
    formatting = { "cmake_format", "gersemi" }
  },
  cpp = {
    diagnostics = { "clang_check", "clazy", "cppcheck", "cpplint", "gccdiag" },
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
    formatting = { "prettier", "prettier_d_slim", "prettier_eslint", "prettierd", "stylelint" }
  },
  cuda = {
    formatting = { "clang_format" }
  },
  cue = {
    diagnostics = { "cue_fmt" },
    formatting = { "cue_fmt", "cueimports" }
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
    formatting = { "erb_format", "erb_lint", "htmlbeautifier" }
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
  fsharp = {
    formatting = { "fantomas" }
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
  gn = {
    formatting = { "gn_format" }
  },
  go = {
    code_actions = { "gomodifytags", "impl", "refactoring" },
    diagnostics = { "golangci_lint", "gospel", "revive", "semgrep", "staticcheck" },
    formatting = { "gofmt", "gofumpt", "goimports", "goimports_reviser", "golines" }
  },
  graphql = {
    formatting = { "prettier", "prettier_d_slim", "prettier_eslint", "prettierd" }
  },
  groovy = {
    diagnostics = { "npm_groovy_lint" },
    formatting = { "npm_groovy_lint" }
  },
  haml = {
    diagnostics = { "haml_lint" }
  },
  handlebars = {
    formatting = { "prettier", "prettier_d_slim", "prettier_eslint", "prettierd" }
  },
  haskell = {
    formatting = { "brittany", "fourmolu", "stylish_haskell" }
  },
  haxe = {
    formatting = { "haxe_formatter" }
  },
  hcl = {
    formatting = { "hclfmt", "packer" }
  },
  html = {
    diagnostics = { "markuplint", "tidy" },
    formatting = { "prettier", "prettier_d_slim", "prettier_eslint", "prettierd", "rustywind", "tidy" }
  },
  htmldjango = {
    diagnostics = { "curlylint", "djlint" },
    formatting = { "djhtml", "djlint" }
  },
  java = {
    diagnostics = { "checkstyle", "npm_groovy_lint", "pmd", "semgrep" },
    formatting = { "astyle", "clang_format", "google_java_format", "npm_groovy_lint", "uncrustify" }
  },
  javascript = {
    code_actions = { "eslint", "eslint_d", "refactoring", "xo" },
    diagnostics = { "deno_lint", "eslint", "eslint_d", "jshint", "semistandardjs", "standardjs", "xo" },
    formatting = { "deno_fmt", "dprint", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_eslint", "prettier_standard", "prettierd", "rome", "rustywind", "semistandardjs", "standardjs" }
  },
  javascriptreact = {
    code_actions = { "eslint", "eslint_d", "xo" },
    diagnostics = { "deno_lint", "eslint", "eslint_d", "semistandardjs", "standardjs", "xo" },
    formatting = { "deno_fmt", "dprint", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_eslint", "prettier_standard", "prettierd", "rome", "rustywind", "semistandardjs", "standardjs" }
  },
  jinja = {
    formatting = { "sqlfmt" }
  },
  ["jinja.html"] = {
    diagnostics = { "curlylint", "djlint" },
    formatting = { "djhtml", "djlint" }
  },
  json = {
    diagnostics = { "cfn_lint", "jsonlint", "spectral", "vacuum" },
    formatting = { "deno_fmt", "dprint", "fixjson", "jq", "json_tool", "prettier", "prettier_d_slim", "prettier_eslint", "prettierd", "rome" }
  },
  jsonc = {
    formatting = { "deno_fmt", "prettier", "prettier_d_slim", "prettier_eslint", "prettierd" }
  },
  jsp = {
    diagnostics = { "pmd" }
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
    formatting = { "prettier", "prettier_d_slim", "prettier_eslint", "prettierd", "stylelint" }
  },
  lua = {
    code_actions = { "refactoring" },
    diagnostics = { "luacheck", "selene" },
    formatting = { "lua_format", "stylua" }
  },
  luau = {
    diagnostics = { "selene" },
    formatting = { "stylua" }
  },
  make = {
    diagnostics = { "checkmake" }
  },
  markdown = {
    code_actions = { "ltrs", "proselint" },
    diagnostics = { "alex", "ltrs", "ltrs", "markdownlint", "markdownlint_cli2", "mdl", "proselint", "textlint", "vale", "write_good" },
    formatting = { "cbfmt", "deno_fmt", "dprint", "markdown_toc", "markdownlint", "mdformat", "ocdc", "prettier", "prettier_d_slim", "prettier_eslint", "prettierd", "remark", "terrafmt", "textlint" },
    hover = { "dictionary" }
  },
  ["markdown.mdx"] = {
    formatting = { "prettier", "prettier_d_slim", "prettier_eslint", "prettierd" }
  },
  matlab = {
    diagnostics = { "mlint" }
  },
  ncl = {
    formatting = { "topiary" }
  },
  nginx = {
    formatting = { "nginx_beautifier" }
  },
  nickel = {
    formatting = { "topiary" }
  },
  nim = {
    formatting = { "nimpretty" }
  },
  nix = {
    code_actions = { "statix" },
    diagnostics = { "deadnix", "statix" },
    formatting = { "alejandra", "nixfmt", "nixpkgs_fmt" }
  },
  ocaml = {
    formatting = { "ocamlformat" }
  },
  octave = {
    diagnostics = { "mlint" }
  },
  org = {
    formatting = { "cbfmt" },
    hover = { "dictionary" }
  },
  pascal = {
    formatting = { "ptop" }
  },
  perl = {
    diagnostics = { "perlimports" },
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
    formatting = { "buf", "clang_format", "protolint" }
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
  purescript = {
    formatting = { "purs_tidy" }
  },
  python = {
    code_actions = { "refactoring" },
    diagnostics = { "flake8", "mypy", "pycodestyle", "pydocstyle", "pylama", "pylint", "pyproject_flake8", "ruff", "semgrep", "vulture" },
    formatting = { "autoflake", "autopep8", "black", "blue", "isort", "pyflyby", "pyink", "reorder_python_imports", "ruff", "usort", "yapf" }
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
    diagnostics = { "opacheck" },
    formatting = { "rego" }
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
    diagnostics = { "reek", "rubocop", "semgrep", "standardrb" },
    formatting = { "rubocop", "rubyfmt", "rufo", "standardrb" }
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
  scheme = {
    formatting = { "emacs_scheme_mode" }
  },
  ["scheme.guile"] = {
    formatting = { "emacs_scheme_mode" }
  },
  scss = {
    diagnostics = { "stylelint" },
    formatting = { "prettier", "prettier_d_slim", "prettier_eslint", "prettierd", "stylelint" }
  },
  sh = {
    code_actions = { "shellcheck" },
    diagnostics = { "dotenv_linter", "shellcheck" },
    formatting = { "beautysh", "shellharden", "shfmt" },
    hover = { "printenv" }
  },
  sls = {
    diagnostics = { "saltlint" }
  },
  sml = {
    formatting = { "smlfmt" }
  },
  solidity = {
    diagnostics = { "solhint" },
    formatting = { "forge_fmt" }
  },
  spec = {
    diagnostics = { "rpmspec" }
  },
  sql = {
    diagnostics = { "sqlfluff" },
    formatting = { "pg_format", "sql_formatter", "sqlfluff", "sqlfmt", "sqlformat" }
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
    diagnostics = { "swiftlint" },
    formatting = { "swift_format", "swiftformat", "swiftlint" }
  },
  systemverilog = {
    diagnostics = { "verilator" },
    formatting = { "verible_verilog_format" }
  },
  teal = {
    diagnostics = { "teal" }
  },
  terraform = {
    diagnostics = { "terraform_validate", "tfsec" },
    formatting = { "terraform_fmt" }
  },
  ["terraform-vars"] = {
    diagnostics = { "terraform_validate", "tfsec" },
    formatting = { "terraform_fmt" }
  },
  tex = {
    code_actions = { "proselint" },
    diagnostics = { "chktex", "proselint", "vale" },
    formatting = { "latexindent" }
  },
  text = {
    code_actions = { "ltrs" },
    diagnostics = { "ltrs" },
    hover = { "dictionary" }
  },
  tf = {
    diagnostics = { "terraform_validate", "tfsec" },
    formatting = { "terraform_fmt" }
  },
  toml = {
    formatting = { "dprint", "taplo" }
  },
  twig = {
    diagnostics = { "twigcs" }
  },
  txt = {
    diagnostics = { "textlint" },
    formatting = { "textlint" }
  },
  typescript = {
    code_actions = { "eslint", "eslint_d", "refactoring", "xo" },
    diagnostics = { "deno_lint", "eslint", "eslint_d", "semgrep", "tsc", "xo" },
    formatting = { "deno_fmt", "dprint", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_eslint", "prettierd", "rome", "rustywind", "standardts" }
  },
  typescriptreact = {
    code_actions = { "eslint", "eslint_d", "xo" },
    diagnostics = { "deno_lint", "eslint", "eslint_d", "semgrep", "tsc", "xo" },
    formatting = { "deno_fmt", "dprint", "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_eslint", "prettierd", "rome", "rustywind", "standardts" }
  },
  verilog = {
    diagnostics = { "verilator" },
    formatting = { "verible_verilog_format" }
  },
  vhdl = {
    formatting = { "emacs_vhdl_mode" }
  },
  vim = {
    diagnostics = { "vint" }
  },
  vue = {
    code_actions = { "eslint", "eslint_d" },
    diagnostics = { "eslint", "eslint_d" },
    formatting = { "eslint", "eslint_d", "prettier", "prettier_d_slim", "prettier_eslint", "prettierd", "rustywind" }
  },
  xml = {
    diagnostics = { "tidy" },
    formatting = { "tidy", "xmlformat", "xmllint", "xq" }
  },
  yaml = {
    diagnostics = { "actionlint", "cfn_lint", "spectral", "vacuum", "yamllint" },
    formatting = { "prettier", "prettier_d_slim", "prettier_eslint", "prettierd", "yamlfix", "yamlfmt", "yq" }
  },
  ["yaml.ansible"] = {
    diagnostics = { "ansiblelint" }
  },
  yml = {
    formatting = { "yq" }
  },
  zig = {
    formatting = { "zigfmt" }
  },
  zsh = {
    diagnostics = { "zsh" },
    formatting = { "beautysh" }
  }
}
