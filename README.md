# omelette.nvim

Neovim support for [Omelette](https://github.com/dennyabraham/omelette-lang) (`.egg`
files).

- Sets the file type `omelette` for `*.egg`.
- Sets `commentstring` to `-- %s` and indents with 2 spaces.
- Starts the Omelette language server, `omelette lsp`, for diagnostics and
  highlighting. Highlighting comes from the server's semantic tokens; the plugin has
  no syntax file, so a file has no colour until the server is running.

## Requirements

- Neovim 0.11 or later.
- `omelette` 0.2.0 or later on your `PATH`: `luarocks install omelette`.

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

The attach test skips unless an `omelette` with the `lsp` command is on `PATH`.

## Design

See the [LSP server and Neovim plugin design](https://github.com/dennyabraham/omelette-lang/blob/canon/docs/superpowers/specs/2026-11-20-lsp-server-design.md).
