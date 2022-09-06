# Testing

- The test suite includes unit and integration tests and depends on
  `plenary.nvim`
- The default `test/minimal.vim` (passed to the instantiation of _Neovim_ with
  `-u`) assumes that you've installed `plenary.nvim` one directory above where
  this project lives, since the test suite modifies `rtp` as follows:

```vim
...
set rtp+=../plenary.nvim
...
```

- Ensure that your plugin directory structure looks something like the
  following:

```vim
.
├── plenary.nvim
└── null-ls
```

## Suite

- Run `make test` in the root of the project to run the test suite.

## Single-file tests

- Run `FILE=test/spec/file_spec.lua make test-file` to run tests from a specific
  file, for example:

```sh
FILE=test/spec/e2e_spec.lua make test-file
```
