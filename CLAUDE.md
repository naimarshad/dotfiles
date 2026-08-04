# dotfiles — session context

## Current work: Neovim as a VSCode replacement (LazyVim)

Goal: replace VSCode with Neovim, using LazyVim, keeping IDE-parity features:
language LSP/lint/format, lazygit, and an in-editor Claude Code terminal.

**Branch:** `machine/workforce` (this machine's dotfiles branch — Debian sid +
KDE Plasma, light theme). Do not merge `main` into this branch — main and
workforce have diverged (different hypr/noctalia/zsh/ghostty configs); only
cherry-pick specific commits across.

### Distro: Debian sid (final)

The install/reinstall plan for this machine is `Debian Sid — Plasma Install
Runbook.md` (repo root) — debootstrap + systemd-boot + btrfs/snapper + KDE
Plasma 6 (Wayland), apt + Flatpak as the two software lanes. Sourced from the
Obsidian vault (`~/Obsidian/personal-runbooks/Debian/debian-sid-plasma-runbook.md`)
and kept in sync with it manually — edit either copy, then port changes to
the other.

The original long-form plan doc lived on branch `claude/neovim-setup-plan-skw4hu`
(background, options considered, VSCode-feature mapping); that branch was an
early draft superseded by the actual implementation on `machine/workforce`
(more extras enabled, more fixes applied) and has been deleted. The plan's
content is summarized below.

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
- [x] `git pull origin machine/workforce` on this machine, restart `nvim` —
      branch was already in sync with remote, nothing to pull
- [x] `:Lazy sync` repeatedly until `Failed (0)` — converged; `lazy-lock.json`
      regenerated with all 50+ plugins resolved (was flaky at first due to the
      documented DNS burst issue, self-resolved on retry)
- [x] Confirm catppuccin latte loads on startup — verified headlessly
      (`vim.g.colors_name == "catppuccin-latte"`, `background == "light"`)
- [x] `:checkhealth` — clean for everything IDE-relevant. Remaining ❌ are
      optional media features (image/PDF/LaTeX/Mermaid preview — need
      `magick`/`tectonic`/`mmdc`, none installed, not needed for coding) and
      `luarocks` (no plugin requires it). Not blockers.
- [x] Go/Rust/Dockerfile/shell/YAML LSPs verified attached headlessly: gopls,
      rust-analyzer, dockerls, bashls, yamlls, helm_ls all attach correctly on
      their respective filetypes. `<leader>cf` format-on-save verified working
      (gofumpt reformats a messy `.go` file correctly).
- [x] `<leader>gg` lazygit — `lazygit` binary installed via apt (was missing)
- [x] `<leader>ac` Claude Code terminal — `claude` CLI confirmed on PATH at
      `~/.local/bin/claude`; `claudecode.nvim` config in `lua/plugins/claude.lua`
      is correct as-is
- [ ] Supermaven ghost-text suggestions — **not verifiable headlessly**, needs
      an interactive session to eyeball ghost-text while typing
- [ ] `<leader>gg` / `<leader>ac` opening the actual TUI panes — also needs an
      interactive session; config is verified correct but not click-tested
- [x] Regenerated `lazy-lock.json` — committed (see below)

**Root cause found and fixed this session: this machine was missing basically
every language toolchain**, not just plugins. `go`, `npm`/`node`, `rustc`/`cargo`,
`python3-venv`, `lazygit`, `ripgrep`, and `fd-find` were all absent, which
silently broke every `mason.nvim` tool/LSP install that depends on them
(gopls, dockerls, bashls, yamlls, jsonls, delve, gofumpt, goimports,
markdown-toc, markdownlint-cli2, yamllint, plus the Snacks picker's fuzzy
finder). All installed via `sudo apt install` (Go/Node/lazygit/venv/rg/fd) and
`rustup` (Rust, with the `rust-analyzer` component) — installed with the
user's confirmation. `~/.zshenv`, `~/.bashrc`, `~/.profile` already source
`~/.cargo/env`, so new shells pick up cargo's PATH automatically.

Also found and fixed (unrelated but blocking): `/etc/apt/sources.list.d/docker.sources`
had appeared mid-session (timestamped today, cause unknown — not created by any
command in this session) missing the required `Suites:` field, which broke
*all* `apt` operations. Fixed by adding `Suites: bookworm`.

Separately, discovered mason.nvim's `ensure_installed` auto-install is
unreliable when driven headlessly/scripted (timing-dependent, silently no-ops
in several attempts) — had to install several LSP servers/tools directly via
`require("mason-registry")` Lua API to get them to actually land. In normal
interactive use (`:Mason`, or just opening files) this should behave as
expected per `mason.nvim`/`mason-lspconfig` semantics.

- [ ] Optional: backport this same IDE setup to `main` and/or to the other
      machine branch `machine/ri-t-0931`, if wanted

### Files touched (all under `nvim/.config/nvim/`, a GNU stow package)
- `lazyvim.json` — extras list
- `lua/config/lazy.lua` — concurrency cap, install-colorscheme fallback
- `lua/config/options.lua` — `ai_cmp`, `confirm`, `background`
- `lua/config/keymaps.lua` — `<C-p>` quick-open
- `lua/plugins/colorscheme.lua` — catppuccin latte
- `lua/plugins/shell.lua`, `lua/plugins/lint.lua`, `lua/plugins/claude.lua` — new
- `lua/plugins/example.lua`, `base16.lua`, `dankcolors.lua`, `lua/matugen*.lua`,
  `lua/plugins/colorscheme` (extensionless) — deleted
