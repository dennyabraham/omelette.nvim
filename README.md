# omelette.nvim

Neovim support for [Omelette](https://github.com/dennyabraham/omelette-lang) (`.egg`
files).

- Sets the file type `omelette` for `*.egg`.
- Sets `commentstring` to `-- %s` and indents with 2 spaces.
- Colors keywords, strings, numbers, comments and constructors with a small syntax
  file, so a file has color without the language server.
- Starts the Omelette language server, `omelette lsp`, which gives:
  - diagnostics as you type;
  - highlighting by what each name refers to, drawn over the syntax file's colors;
  - hover (`K`): a name's type, or a type's declaration;
  - go to definition (`CTRL-]`), within the same file;
  - the file's outline (`gO`).

See `:help omelette`.

## Requirements

- Neovim 0.11 or later.
- `omelette` on your `PATH`: `luarocks install omelette`. Diagnostics and highlighting
  need 0.2.0 or later; hover, go to definition and the outline need 0.3.0 or later.

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "dennyabraham/omelette.nvim" }
```

To change the server settings, override them with `vim.lsp.config("omelette", { ... })`.

## Tests

```sh
nvim --clean --headless -l tests/run.lua
```

The server tests skip unless an `omelette` with the `lsp` command is on `PATH`, and
the hover test skips for an `omelette` older than 0.3.0.

## Design

See the [LSP server and Neovim plugin design](https://github.com/dennyabraham/omelette-lang/blob/canon/docs/superpowers/specs/2026-11-20-lsp-server-design.md).
