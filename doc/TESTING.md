# Testing

- The test suite includes unit and integration tests and depends on `plenary.nvim`
- The default `test/minimal.vim` (passed to the instantiation of _Neovim_ with
  `-u`) assumes that `plenary.nvim` is installed one directory above where this
  project lives. This is noted by:

```
...
set rtp+=../plenary.nvim
...
```

- From this, ensure that you have a directory structure that is something like the
  following:

```
.
├── plenary.nvim
└── null-ls
```

- As an additional note, the command used in the `Makefile` instantiates _Neovim_ with
  `-u`, which does _not_ skip plugins in `start/` directories on `packpath`. We need
  plugins to load in order for testing to work, so we can't use `--no-plugin` either.
  If you have problems with _Neovim_ starting when running tests, try passing `--clean`
  (by temporarily editing the commands in the `Makefile`), which allows us to not load
  `start/` plugins by _default_, but still ensures that we can load plugins that are
  manually added to our `:h runtimepath`.

## Unit

- Run `make test` in the root of the project to run the unit test suite

## Functional

- Run `FILE=test/spec/file_spec.lua make test-file` to run functional tests from
  a specific file, for example:

```
$ FILE=test/spec/e2e_spec.lua make test-file
```
