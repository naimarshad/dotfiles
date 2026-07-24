-- Shell (bash/sh) + fish support.
-- LazyVim has no `lang.bash` extra, so we wire up the LSP, formatter, and
-- linter by hand. bash-language-server is auto-installed by mason-lspconfig
-- when listed under `servers`; the CLI tools come from mason's ensure_installed.
return {
  -- LSP: bashls for sh/bash
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
      },
    },
  },

  -- Install shfmt (format) + shellcheck (lint) via Mason
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "shfmt", "shellcheck" } },
  },

  -- Format: shfmt for shell, fish_indent for fish (both bundled in conform)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        bash = { "shfmt" },
        fish = { "fish_indent" },
      },
    },
  },

  -- Lint: shellcheck for shell scripts
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
      },
    },
  },
}
