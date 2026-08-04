# Repository Guidelines

Personal dotfiles for the `workforce` machine, managed with **GNU stow**. This is a configuration repository: there is no build step and no application test suite. Verify changes by reloading the affected tool and checking the result.

## Project Overview

A stow-managed dotfiles tree for a Debian sid workstation. It covers shell, editor, terminal, window manager, and desktop-shell configuration: zsh + Powerlevel10k, fish + Starship, LazyVim-based Neovim, Ghostty, tmux, Hyprland, Noctalia, and supporting recovery notes.

## Architecture & Data Flow

- **Install model:** each top-level package directory is stowed into `$HOME`.
- **Config flow:** edit repo file → `stow` or reload the target app → verify the runtime picks up the change.
- **Shared theme spine:** Catppuccin Latte / light theme conventions are reused across nvim, ghostty, btop, tmux, Hyprland helper colors, and shell prompts.
- **Shared safety pattern:** kubectl-related helpers wrap or colorize the real `kubectl` command; zsh adds the strongest prod-context guard rails, tmux and prompt config reflect the same context coloring.
- **Desktop integration:** Hyprland launches and then talks to Noctalia through `qs -c noctalia-shell ipc call ...` endpoints for launcher, lock screen, notifications, media, and settings.

## Key Directories

| Dir | Purpose |
|---|---|
| `zsh/` | zsh shell setup and Powerlevel10k config |
| `fish/` | fish shell config, plugins, aliases, and prompt bootstrap |
| `starship/` | helper scripts used by Starship |
| `nvim/` | LazyVim-based Neovim configuration |
| `ghostty/` | Ghostty terminal config |
| `btop/` | btop config and themes |
| `noctalia/` | Quickshell/desktop-shell settings and plugins |
| `hypr/` | Hyprland config, launch script, autostart, keybinds, and window rules |
| `tmux/` | tmux config, theme integration, and custom status scripts |
| `system/` | Machine-state snapshots and recovery notes; treat as recovery material, not normal app code |

## Development Commands

There is no build pipeline. Typical workflow:

```bash
# Refresh stowed configs from the repo root
stow zsh ghostty hypr btop fish
stow */

# Remove a stow package
stow -D <pkg>

# Reload the live app after edits
hyprctl reload
tmux source-file ~/.config/tmux/tmux.conf
:p10k reload
:Lazy sync

# Quick checks
fc-match monospace
```

## Code Conventions & Common Patterns

- **Stow layout:** keep package contents in paths that mirror the destination, for example `nvim/.config/nvim/init.lua` or `ghostty/.config/ghostty/config`.
- **Branching:** host-specific work stays on the `machine/workforce` branch; avoid mixing it with other host branches unless you are cherry-picking a specific commit.
- **Comments matter:** configs document why a setting exists, not just what it is. Preserve that style.
- **Shell conventions:** `nvim` is the editor locally, `vim` over SSH; `kubecolor` is wrapped around `kubectl`; `gro` jumps to the git root; SSH host aliases are mirrored across shells.
- **Neovim pattern:** `init.lua` bootstraps `config.lazy`; shared settings live in `lua/config/{lazy,options,keymaps,autocmds}.lua`; feature overrides live in `lua/plugins/*.lua`.
- **Neovim AI stack:** `vim.g.ai_cmp = false` keeps Supermaven as ghost text rather than menu completion; Claude Code uses the `coder/claudecode.nvim` terminal integration.
- **Shell prompt split:** zsh uses oh-my-zsh + Powerlevel10k; fish uses Starship.
- **Theme consistency:** use the existing light palette and Catppuccin Latte conventions instead of introducing a second theme.
- **Error handling:** helper scripts are usually best-effort with sensible fallbacks; keep that style unless the runtime requires hard failure.

## Important Files

| File | Role |
|---|---|
| `CLAUDE.md` | AI-agent session context, branch policy, known issues, and current implementation notes |
| `README.md` | Minimal repository placeholder |
| `README.reinstall.md` | Host recovery / reproduction note |
| `zsh/.p10k.zsh` | Generated Powerlevel10k config |
| `fish/.config/fish/config.fish` | fish entrypoint and Starship init |
| `.config/starship.toml` | Starship prompt config used by fish |
| `nvim/.config/nvim/init.lua` | Neovim entrypoint; bootstraps LazyVim |
| `nvim/.config/nvim/lua/config/lazy.lua` | lazy.nvim bootstrap and plugin loading |
| `nvim/.config/nvim/lua/plugins/*.lua` | Neovim plugin overrides and feature specs |
| `hypr/.config/hypr/hyprland.conf` | Hyprland entrypoint; sources the rest of the compositor config |
| `hypr/.config/hypr/start-hyprland.sh` | TTY launcher for Hyprland |
| `tmux/.config/tmux/tmux.conf` | tmux entrypoint and theme/module wiring |
| `noctalia/.config/noctalia/settings.json` | Noctalia desktop-shell settings |
| `.claude/settings.local.json` | Claude Code permission allowlist |

## Runtime / Tooling Preferences

- **Base OS:** Debian sid on the current machine.
- **Package manager:** use `apt` for host tools; there is no project package manager.
- **Rust:** prefer `rustup` over distro Rust packages.
- **Neovim:** plugins are managed by `lazy.nvim`, not by npm/pnpm/cargo.
- **Shell tools:** `oh-my-zsh`, `powerlevel10k`, `fisher`, `starship`, `fzf`, `kubecolor`, `eza`, `bat`, `lazygit`, `ripgrep`, `fd`, and `python3-venv` are part of the expected toolchain.
- **Current repo notes:** `starship/` provides helper scripts; the Starship TOML lives at the top-level `.config/starship.toml`.

## Testing & QA

There is no automated test suite. Use the runtime itself as the check:

- `hyprctl reload` after compositor changes.
- `tmux source-file ~/.config/tmux/tmux.conf` after tmux edits.
- `:Lazy sync` or `:Lazy check` after Neovim plugin changes.
- `fc-match monospace` after font or prompt/theme changes.
- Open a new shell and confirm zsh or fish picks up alias, PATH, and prompt changes.

## Notes for AI Assistants

- Read `CLAUDE.md` first before changing machine-specific behavior.
- Preserve the existing stow layout; do not flatten package directories.
- Keep the two shell stacks in sync where they intentionally overlap: kubectl wrappers, SSH aliases, editor choice, and `gro`.
- Avoid introducing a second theme system. Extend the existing light palette conventions.
- If a change affects multiple runtimes, update the corresponding package directories together and verify each runtime separately.
