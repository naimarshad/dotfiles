# dotfiles — session context

## Current work: Neovim as a VSCode replacement (LazyVim)

Goal: replace VSCode with Neovim, using LazyVim, keeping IDE-parity features:
language LSP/lint/format, lazygit, and an in-editor Claude Code terminal.

**Branch:** `machine/workforce` (this machine's dotfiles branch — Debian sid +
KDE Plasma, light theme). Do not merge `main` into this branch — main and
workforce have diverged (different hypr/noctalia/zsh/ghostty configs); only
cherry-pick specific commits across.

**Full plan doc** (background, options considered, VSCode-feature mapping):
`NEOVIM_IDE_PLAN.md` on branch `claude/neovim-setup-plan-skw4hu` (main-based,
not yet on workforce — the plan's content is summarized below, this is just
where the long-form version lives if needed).

### Decisions locked in
- Languages: Go, Rust, + DevOps (Shell, Docker, YAML, Helm, JSON, TOML, Markdown, Git)
- AI pair programming: `coder/claudecode.nvim` via LazyVim's `ai.claudecode` extra
- Inline AI completion: Supermaven via LazyVim's `ai.supermaven` extra (ghost-text
  mode, `vim.g.ai_cmp = false` in `lua/config/options.lua`)
- Colorscheme: **catppuccin latte** (light, to match KDE Plasma light theme) —
  `lua/plugins/colorscheme.lua`. Previously there were 3 competing colorscheme
  systems (base16-nvim/dankcolors/matugen + a stray gruvbox/catppuccin file);
  all removed in favor of this single spec.

### Commits landed on `machine/workforce` (chronological, all pushed)
1. `c6dc03f` — shell.lua (bashls/shfmt/shellcheck), lint.lua (yamllint/actionlint),
   claude.lua (claudecode.nvim terminal opts), filled options.lua/keymaps.lua
   stubs, deleted inert plugins/example.lua
2. `6d1edac` — enabled 17 LazyVim extras in `lazyvim.json` (was empty — this was
   the root cause of "not an IDE": zero language extras means zero LSP/format/lint
   installed)
3. `1aa7222` — capped `concurrency = 10` in `lua/config/lazy.lua` to reduce DNS
   flooding during `:Lazy sync` (see Known issue below)
4. `5118aaf` — removed base16-nvim/dankcolors.lua/matugen.lua/matugen-template.lua
   and a stray extensionless `lua/plugins/colorscheme` file; replaced with
   catppuccin-latte in `lua/plugins/colorscheme.lua`; updated `lazy.lua`'s
   install-time fallback colorscheme and set `vim.opt.background = "light"`

### Known issue: `:Lazy sync` DNS flakiness (not a config bug)
Symptom: `:Lazy sync` / `:LazyExtras` shows plugins failing with
`fatal: unable to access '...git/': Could not resolve host: github.com`.
This is **not** wrong repo names or a code bug — shell `git clone` and
`getent hosts github.com` both work fine outside nvim. Root cause: lazy.nvim
fires many concurrent git fetches on a fresh/large sync (was 50+, now capped at
10), which floods the home router's DNS resolver (`192.168.1.1`) under burst
load. It's intermittent and self-resolves: **re-running `:Lazy sync` repeatedly
converges to `Failed (0)`** as fewer plugins remain to fetch each pass.
If it keeps not converging, the durable fix is switching this machine's DNS off
the router onto a public resolver (1.1.1.1 / 8.8.8.8) via NetworkManager, not a
config change.

### Next steps / verification checklist
- [ ] `git pull origin machine/workforce` on this machine, restart `nvim`
- [ ] `:Lazy sync` repeatedly until `Failed (0)` — no plugin left uninstalled
- [ ] Confirm catppuccin latte loads on startup (no more dark-theme fallback)
- [ ] `:checkhealth` — clean, especially treesitter (needs a C compiler:
      `cc`/`gcc`/`make` — install `build-essential` on Debian if missing)
- [ ] Open a `.go` / `.rs` file → `:LspInfo` shows an attached server, `K` hovers,
      `<leader>cf` formats
- [ ] Open a `Dockerfile` / `values.yaml` → diagnostics from hadolint/yaml-ls
- [ ] `<leader>gg` → lazygit opens (needs `lazygit` binary installed on the system)
- [ ] `<leader>ac` → Claude Code terminal toggles (needs `claude` CLI on PATH);
      `<leader>ab` adds current buffer as context; visual-select + `<leader>as`
      sends selection; `<leader>aa` / `<leader>ad` accept/deny a diff
- [ ] Typing in a code buffer shows Supermaven ghost-text suggestions
- [ ] Once stable, commit the regenerated `lazy-lock.json` to pin versions
- [ ] Optional: backport this same IDE setup to `main` (already on
      `claude/neovim-setup-plan-skw4hu`) and/or to the other machine branch
      `machine/ri-t-0931`, if wanted

### Files touched (all under `nvim/.config/nvim/`, a GNU stow package)
- `lazyvim.json` — extras list
- `lua/config/lazy.lua` — concurrency cap, install-colorscheme fallback
- `lua/config/options.lua` — `ai_cmp`, `confirm`, `background`
- `lua/config/keymaps.lua` — `<C-p>` quick-open
- `lua/plugins/colorscheme.lua` — catppuccin latte
- `lua/plugins/shell.lua`, `lua/plugins/lint.lua`, `lua/plugins/claude.lua` — new
- `lua/plugins/example.lua`, `base16.lua`, `dankcolors.lua`, `lua/matugen*.lua`,
  `lua/plugins/colorscheme` (extensionless) — deleted
