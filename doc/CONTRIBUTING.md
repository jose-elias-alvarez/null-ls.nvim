# Contributing

## General

- Before committing, please format Lua files with
  [StyLua](https://github.com/JohnnyMorganz/StyLua) and Markdown files with
  [Prettier](https://github.com/prettier/prettier). Both are available as
  null-ls built-ins.

- Use the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
  style for your commits.

- Squash your commits so that one commit represents one complete change.

- Mark your PR as WIP until it's ready to merge.

## Contributing built-ins

- Check if there is an open issue requesting the built-in you are adding and
  mention in your PR that it closes any relevant issue(s).

- Check other built-in sources for examples and, whenever possible, use helpers
  to reduce the number of lines of code in your PR.

- Make sure to add your built-in source to [BUILTINS](BUILTINS.md). Check other
  examples and follow the existing style.
