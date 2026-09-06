# dotfiles — session context

## What this branch is

**Branch:** `machine/workforce` — this machine's dotfiles. ThinkPad T490, **Debian testing** (rolling `testing` alias, currently forky), light theme throughout (Catppuccin Latte).

Desktop: **niri** (Wayland scrolling compositor, built from source) with **Noctalia** as the desktop shell (apt package from `pkg.noctalia.dev`). Display manager is **greetd + noctalia-greeter**. **GNOME stays installed** as a fallback session at the greeter.

Do not merge `main` into this branch. `main` and `machine/workforce` have deliberately diverged (different compositor, shell, and OS assumptions). Cross-pollinate by cherry-picking specific commits only. The other machine branch is `machine/ri-t-0931`; the `niri/` package here was copied from it by hand, not merged.

Git identity is set at `--local`: `Naeem Arshad <naimarshad@gmail.com>` (personal repo).

## Authoritative reinstall runbook

`Debian Testing - GNOME Install Runbook.md` at the repo root, **Rev 4**. It is a verified record, not a plan: every step was reconciled against `~/.bash_history`, `~/.zsh_history`, and the running system. It is mirrored to `~/Obsidian/Runbooks/Debian/debian-testing-gnome-runbook.md` and the two are kept in sync by hand (edit either, port to the other).

`Debian Sid — Plasma Install Runbook.md` is the superseded predecessor, kept for history.

Steps at a glance: debootstrap + systemd-boot + btrfs/snapper spine (Steps 00-09), minimal GNOME (10-16), niri source build + Noctalia apt repo + awww wallpaper daemon (17), then a dev-tooling layer: shell environment (18), containers/Kubernetes (19), virtualization (20), editors and desktop apps (21), sync/networking (22).

## Machine facts worth knowing

- **Compositor:** `niri` built from `github.com/niri-wm/niri` to `/usr/local/bin/niri`. Version bump = `git pull && cargo build --release` + re-copy the `resources/` files (runbook Step 17e).
- **Shell:** `noctalia` binary at `/usr/bin/noctalia`, launched from `niri/.config/niri/autostart.kdl` (`spawn-at-startup "noctalia"`). Noctalia 5 IPC is `noctalia msg <verb>`; Noctalia 4's `qs -c noctalia-shell ipc call ...` is gone and `qs` is not installed. The `binds.kdl` and `autostart.kdl` IPC calls were migrated 4→5 (calendar and now-playing are `control-center` tabs now, not standalone panels).
- **Wallpaper:** `awww` (LGFae's maintained successor to the archived `swww`), source-built to `/usr/local/bin`. Needed `wayland-protocols` + `cmake` to build; the lz4 packages from the first failed attempt were a red herring.
- **Not in the Debian archive, installed from upstream:** `ghostty` (ghostty-ubuntu installer script), `mise` (`mise.run`), `k9s` (release `.deb`), `sops` (release binary), `niri` + `awww` (source). Everything else is apt or system-wide Flatpak.
- **`~/.zshrc` expects:** `kubecolor` (wraps `kubectl`), `kubie` (context isolation), plus the usual oh-my-zsh + Powerlevel10k + mise stack. `starship` has a stow package but is unused (prompt is p10k).
- **Stow packages actually used here:** `ghostty zsh niri noctalia nvim tmux`. `hypr`, `fish`, `starship` are retained but dormant. `k9s` and `btop` stow once their binaries are in.

## Neovim IDE setup (done)

The LazyVim-based "Neovim as a VSCode replacement" work is complete and shipped on this branch. Languages: Go, Rust, + DevOps (Shell, Docker, YAML, Helm, JSON, TOML, Markdown, Git). AI: `coder/claudecode.nvim` (via `ai.claudecode` extra) and Supermaven ghost-text (via `ai.supermaven`, `vim.g.ai_cmp = false`). Colorscheme: catppuccin latte (`lua/plugins/colorscheme.lua`), single spec, `vim.opt.background = "light"`. Extras live in `nvim/.config/nvim/lazyvim.json`.

Known issue, not a config bug: `:Lazy sync` on a large/fresh sync fires many concurrent git fetches and floods the home router's DNS resolver, showing `Could not resolve host: github.com`. `concurrency = 10` in `lua/config/lazy.lua` reduces it; re-running `:Lazy sync` converges to `Failed (0)`. Durable fix is a public DNS resolver on this machine, not a config change.

## Open items

- Large uncommitted working-tree diff from the rebuild: `noctalia/` was regenerated from the live `~/.config/noctalia` and `niri/` was added from `machine/ri-t-0931`. Commit per file / logical unit.
- Optional: backport the IDE setup or the niri/Noctalia config to `main` or `machine/ri-t-0931` if wanted.
