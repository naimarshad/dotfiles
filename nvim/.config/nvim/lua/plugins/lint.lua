-- Extra DevOps linters not bundled by the language extras.
-- (hadolint for Dockerfiles comes from the `lang.docker` extra; yaml-ls
-- schema validation comes from `lang.yaml`. Here we add the standalone
-- YAML style linter and a GitHub Actions workflow linter.)
return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "yamllint", "actionlint" } },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        yaml = { "yamllint" },
        -- LazyVim sets the `yaml.github` filetype for files under
        -- .github/workflows/, so actionlint only runs on those.
        ["yaml.github"] = { "actionlint" },
      },
    },
  },
}
