# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Layout

This is a personal dotfiles repo using a **Stow-compatible directory structure**: each top-level package folder mirrors the target path from `$HOME`. For example, `niri/.config/niri/` symlinks to `~/.config/niri/`.

Packages on this branch: `btop`, `fish`, `fontconfig`, `ghostty`, `gtk`, `hypr`, `niri`, `noctalia`, `nvim`, `starship`, `zsh`.

To deploy a package: `stow -d ~/dotfiles -t "$HOME" <package>`

## Machine Branches

Shared config lives on `main`. Each machine gets its own long-lived branch, and the package sets themselves diverge, not just a few files:

- `main` is the shared Hyprland-era base, and has no `niri` or `gtk` package.
- `machine/ri-t-0931` is the primary work machine: niri compositor, light Catppuccin Latte theme, three outputs at home (HDMI-A-1 ultrawide, DP-1 rotated vertical, eDP-1 laptop panel) plus a Lenovo P34w-20 ultrawide at the office.
- `machine/workforce` is Debian Sid with Plasma, and carries `k9s` and `tmux` packages the others do not.

Share code between branches by cherry-picking specific commits. Do not merge `main` into a machine branch, since it drags in an unrelated package set.

Files that typically differ per machine: `niri/.config/niri/outputs.kdl` (output geometry and workspace pinning) and `niri/.config/niri/rules.kdl` (per-app window rules).

The office dock enumerates the P34w-20 as either `DP-3` or `DP-5` depending on port and MST branch, so `outputs.kdl` configures both connectors identically at `x=6680`. Only one is ever live at a time.

## Niri Config Architecture (`niri/`)

This machine runs [niri](https://github.com/YaLTeR/niri), a scrolling Wayland compositor configured in KDL. `config.kdl` is a near-pure entry point: it sets `prefer-no-csd` and then `include`s the rest in order.

```
environment.kdl → cursor theme, Wayland/Qt/GTK/Electron env vars
outputs.kdl     → output modes, positions, scale, and workspace pinning (machine-specific)
input.kdl       → keyboard, mouse, touchpad, focus-follows-mouse
layout.kdl      → gaps, column widths, focus ring, shadows, animation springs
rules.kdl       → window rules: blur, opacity, corner radius, floating, workspace assignment
autostart.kdl   → spawn-at-startup services and apps
binds.kdl       → all keybinds
noctalia.kdl    → generated colours (focus ring, border, shadow, tab indicator)
```

`niri/.config/niri/` also holds three helper scripts, each of which logs to `~/.cache/`:

- `start-niri.sh` execs `niri-session` rather than plain `niri`, so the ScreenCast D-Bus interface registers and the GNOME portal can do window and monitor capture. Call it from `~/.zprofile`.
- `workspace-location.sh` moves the main workspaces onto the office ultrawide when HDMI-A-1 is absent. It matches that monitor by model (`P34w-20`) rather than by connector, precisely because the connector name is not stable across docks, and it exits non-zero with a logged reason if `niri msg` returns nothing or the model is not found. The `open-on-output "HDMI-A-1"` pins in `outputs.kdl` cover the home case on their own, so the script exits early there. It parses with `jq`, which is therefore a runtime dependency.
- `wallpaper.sh` fetches a rotating Unsplash wallpaper and sets it via `awww`. It needs `~/.config/niri/unsplash-key`, which is gitignored.

### Useful Niri Commands

```bash
niri validate                   # Check the config parses before reloading
niri msg action reload-config   # Reload config (also bound to Mod+Shift+R)
niri msg outputs                # List connected outputs and their modes
niri msg --json outputs         # Same, machine-readable, as used by workspace-location.sh
niri msg --help                 # Authoritative subcommand list, it changes between versions
```

Window rules match on `app-id` and `title` using Rust regex, written as `r#"^pattern$"#`. Read the real `app-id` off the running window through `niri msg` rather than guessing it from the binary name, and check `niri msg --help` for the current window-listing subcommand.

## Hyprland Config (`hypr/`), legacy

The `hypr` package predates the niri migration (commit `a4af0b6`) and is kept for reference only. It is not the live compositor on this branch. `hyprland.conf` sources `env.conf`, `monitor.conf`, `general.conf`, `decoration.conf`, `animations.conf`, `input.conf`, `layouts.conf`, `keybinds.conf`, `windowrules.conf`, `workspaces.conf`, `autostart.conf`, and finally `noctalia/noctalia-colors.conf`. Treat changes here as archival unless the migration is being reversed.

## Noctalia Shell (`noctalia/`)

Noctalia is a Qt/QML desktop shell built on [Quickshell](https://quickshell.outfoxxed.me). Launched from `autostart.kdl` via:

```bash
qs -c noctalia-shell --no-duplicate
```

IPC calls from keybinds use: `qs -c noctalia-shell ipc call <target> <action>`, for example `qs -c noctalia-shell ipc call launcher toggle`.

**Plugin structure**: each plugin under `plugins/` contains:

- `manifest.json` for id, version, entryPoints, and defaultSettings
- `BarWidget.qml` for the bar icon or widget
- `Panel.qml` for the expanded panel UI
- `Settings.qml` for the settings pane
- `Main.qml` for service and logic entry

Which plugins are enabled is tracked in `plugins.json`, not in the plugin directories.

**Colours are generated, not hand-edited.** `settings.json` selects the scheme under `colorSchemes` (`predefinedScheme`, plus `darkMode` choosing the scheme file's `light` or `dark` palette). Noctalia then renders that palette into every app listed in `templates.activeTemplates`, producing `niri/.config/niri/noctalia.kdl`, `gtk/.config/gtk-3.0/noctalia.css`, `gtk/.config/gtk-4.0/noctalia.css`, and `hypr/.config/hypr/noctalia/noctalia-colors.conf`. All of those are committed so a fresh checkout looks right before Noctalia first runs. Change the scheme and let it regenerate; hand-editing a generated file is overwritten on the next render.

Ghostty is deliberately outside that system. It is not in `activeTemplates` and pins `theme = "Catppuccin Latte"` in its own config, so terminal colours are changed there by hand.

## Neovim Config (`nvim/`)

LazyVim-based. `lua/config/` holds `autocmds.lua`, `keymaps.lua`, `lazy.lua`, and `options.lua`. `lua/plugins/` holds the overrides, including `colorscheme.lua`. Plugin versions are pinned in `lazy-lock.json`.

## Shells

Two shells are configured, with different prompts, so a prompt change usually needs making twice.

**Zsh (`zsh/`)** uses Oh My Zsh with Powerlevel10k:

- `.zshrc` for the plugin list, exports, and aliases
- `.p10k.zsh` for the prompt config, shared across machines
- `.kube/kubie.yaml` for the kubie context switcher

`.zshrc` also wraps `kubectl` and `helm` in production guards, which are the most delicate thing in the file. When the current context matches `_PROD_PATTERN`, a destructive subcommand prompts for confirmation before running. The verb is decided by walking the arguments, skipping anything starting with `-`, and taking the first token that appears in either the read-only or the dangerous list, so `kubectl -n default delete pod` is caught and `helm diff upgrade` is not a false alarm. Read-only is checked first for exactly that reason. Each function re-asserts its patterns with `: "${VAR:=default}"`, because an unset pattern would leave `grep -E` testing an empty regex, which matches everything and would make every command look dangerous. Keep both properties if you touch these.

**Fish (`fish/`)** uses Starship, with fzf key bindings, gitnow, and `kubectl`/`k` wrapped to `kubecolor`. Note that `starship.toml` itself lives at the repo root under `.config/`, not inside the `starship` package.

## Key Environment Details

- **Terminal**: Ghostty (`com.mitchellh.ghostty`), theme pinned to `Catppuccin Latte`, font `JetBrainsMono NF Regular`
- **Cursor theme**: `Bibata-Modern-Classic` at size 24, set in `niri/environment.kdl` (both the `cursor` block and `XCURSOR_THEME`) and in the GTK settings
- **GTK theme**: `adw-gtk3` with the `Catppuccin-Macchiato` icon theme and `Inter 12`
- **Screenshots**: niri's built-in actions on the `Print` keys (`screenshot`, `Mod+Print` for screen, `Mod+Shift+Print` for window). There is no `HYPRSHOT_DIR` under niri.
- **Niri keybind prefix**: `Mod` is the Super key. Noctalia binds spawn `qs -c noctalia-shell ipc call ...` directly, since KDL has no variable expansion.

## Known Quirks

Worth knowing before assuming something is a bug you introduced:

- `.config/starship.toml` sits at the repo root instead of in `starship/.config/`, so `stow starship` deploys only `cpu.sh` and `netinfo.sh`.
- `noctalia/.config/noctalia/plugins-loca/` is a partial duplicate of `plugins/`, and contains a stray `terraform.tfstate` that has nothing to do with the shell.
- `noctalia/.config/noctalia/plugins/github-feed/cache/events.json` is a runtime cache but is tracked, so it churns in diffs.
- `ghostty/.config/ghostty/config` sets `background-blur-radius` twice, at 80 and then 60, left over from resolving a merge conflict. Only one value can win. `theme` is set once.
- `ghostty/.config/ghostty/themes/noctalia` is now dormant, since the config pins `Catppuccin Latte` and ghostty is not in `activeTemplates`.
- `KUBECOLOR_LIGHT_BACKGROUND=true` is exported twice in `.zshrc`, near the top and again at the bottom.
- Several files once carried committed merge conflict markers, including `settings.json`, which left it as invalid JSON. Run `jq empty noctalia/.config/noctalia/settings.json` after touching it, and grep for `<<<<<<<` before committing a resolution.

## Secrets

`.gitignore` keeps kubeconfigs (`zsh/.kube/config*`, `zsh/.kube/configs/`), the Unsplash API key (`niri/.config/niri/unsplash-key`), and the github-feed plugin's personal access token (`noctalia/.config/noctalia/plugins/github-feed/settings.json`) out of the repo. This is a public repo, so check any new config file for tokens before adding it.
