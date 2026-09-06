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

Noctalia 5 is a standalone desktop shell binary. Launched from `autostart.kdl` via:

```bash
noctalia
```

IPC calls from keybinds use `noctalia msg <verb>`, for example `noctalia msg panel-toggle launcher`. Verify verbs against `noctalia msg --help` on the installed build; they drifted between v4 and v5.

**This branch migrated v4 -> v5.** Noctalia 4 was a [Quickshell](https://quickshell.outfoxxed.me) config launched as `qs -c noctalia-shell --no-duplicate`, with IPC as `qs -c noctalia-shell ipc call <target> <action>`. That interface is gone and `qs` is not needed. The legacy AUR `noctalia-qs` / `noctalia-shell` packages are still v4; do not install them. The v4 to v5 bind mapping used here:

| v4 | v5 |
| --- | --- |
| `launcher toggle` | `panel-toggle launcher` |
| `launcher windows` | `window-switcher` |
| `launcher emoji` | `panel-toggle launcher /emo` |
| `launcher clipboard` | `panel-toggle clipboard` |
| `settings toggle` | `settings-toggle` |
| `calendar toggle` | `panel-toggle control-center calendar` |
| `controlCenter toggle` | `panel-toggle control-center` |
| `lockScreen lock` | `session lock` |
| `sessionMenu toggle` | `panel-toggle session` |
| `notifications toggleDND` | `notification-dnd-toggle` |
| `mediaControls toggle` | `panel-toggle control-center media` |

Calendar and now-playing are control-center tabs in v5, not standalone panels. The v5 control-center tabs are `home audio bluetooth calendar media monitor network notifications power system weather`; the standalone panels are `launcher clipboard session wallpaper`.

**Idle, screen-off and lock-before-sleep belong to Noctalia 5**, under `[idle]` in `settings.toml` (`behavior_order` plus an `[idle.behavior.<name>]` table each, with `action` and `timeout`). Noctalia registers its own systemd sleep inhibitor, visible as `noctalia ... sleep "Lock before sleep"` in `systemd-inhibit --list`, so the old `swayidle -w` line was removed from `autostart.kdl` in the v5 migration: running both double-fired the lock at the shared 300s timeout. Check `systemd-inhibit --list` before assuming a lock-on-suspend regression is a Noctalia bug.

**Config location.** v5 keeps its settings at `~/.local/state/noctalia/settings.toml`, not `~/.config/noctalia/`. That means `noctalia` is **not a stow package** any more: the file holds plugin credentials (`api_key`, `api_secret`, `kubeconfig`), and this is a public repo, so it is tracked SOPS/age-encrypted as `noctalia/settings.sops.toml` and decrypted into place on a rebuild:

```bash
sops --decrypt noctalia/settings.sops.toml > ~/.local/state/noctalia/settings.toml
noctalia msg config-reload
```

SOPS has no TOML parser, so it encrypts the whole file as one opaque blob. It round-trips, but diffs on it are not readable. The age private key at `~/.config/sops/age/keys.txt` (mode 600, `SOPS_AGE_KEY_FILE` exported from `.zshrc`) is the only way to read it; back it up outside this repo.

**Plugins** are configured in `settings.toml` under `[plugins] enabled` and `plugin_settings.<id>` tables, and credentials are entered through the GUI (`noctalia msg settings-open-plugin <author/plugin>`), never by hand. The v4 tree of QML plugin directories (`manifest.json` + `BarWidget.qml` / `Panel.qml` / `Settings.qml` / `Main.qml`, with `plugins.json` tracking which were enabled) was removed in the v5 migration; a plugin needs a v5 port to come back. `next-meeting` is the one whose port status is unverified, and its gitlink had no `.gitmodules` entry, so its upstream URL is not recoverable from this repo.

**`noctalia/BAR-LAYOUT-v4.md`** records what every output's bar held under v4 (`HDMI-A-1`, `DP-3`, `DP-5`, `DP-6`, `DP-1`, `eDP-1`), since the v4 `settings.json` is gone. Rebuild the v5 bars from it. It carries no secrets: every credential field was empty in the source.

**Colours are generated, not hand-edited.** The scheme is selected in `settings.toml`, and Noctalia renders that palette into every app in its active-template list, producing `niri/.config/niri/noctalia.kdl`, `gtk/.config/gtk-3.0/noctalia.css`, `gtk/.config/gtk-4.0/noctalia.css`, and `hypr/.config/hypr/noctalia/noctalia-colors.conf`. All of those are committed so a fresh checkout looks right before Noctalia first runs. Change the scheme and let it regenerate; hand-editing a generated file is overwritten on the next render. The `gtk` templates are confirmed working under v5: `gtk-4.0/gtk.css` changed from a symlink into `adw-gtk3` to a real file that `@import`s `noctalia.css`, and both `noctalia.css` files regenerate.

Ghostty is **inside** that system as of the v5 migration: its config sets `theme = noctalia` and Noctalia renders `ghostty/.config/ghostty/themes/noctalia`. It was pinned to `Catppuccin Latte` and hand-managed under v4; `machine/workforce` made the same switch in `5a7403e`.

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
- **Niri keybind prefix**: `Mod` is the Super key. Noctalia binds spawn `noctalia msg ...` directly, since KDL has no variable expansion.

## Known Quirks

Worth knowing before assuming something is a bug you introduced:

- `.config/starship.toml` sits at the repo root instead of in `starship/.config/`, so `stow starship` deploys only `cpu.sh` and `netinfo.sh`.
- `ghostty/.config/ghostty/config` sets `background-blur-radius` twice, at 80 and then 60, left over from resolving a merge conflict. Only one value can win. `theme` is set once.
- `ghostty/.config/ghostty/themes/noctalia` is now dormant, since the config pins `Catppuccin Latte` and ghostty is not in `activeTemplates`.
- `KUBECOLOR_LIGHT_BACKGROUND=true` is exported twice in `.zshrc`, near the top and again at the bottom.
- Several files have carried committed merge conflict markers in the past. Grep for `<<<<<<<` before committing a resolution. (The worst offender, Noctalia's v4 `settings.json`, is gone with the v5 migration.)

## Secrets

`.gitignore` keeps kubeconfigs (`zsh/.kube/config*`, `zsh/.kube/configs/`) and the Unsplash API key (`niri/.config/niri/unsplash-key`) out of the repo. This is a public repo, so check any new config file for tokens before adding it.

Under Noctalia 5 every plugin credential (the github-feed PAT, `kubeconfigPath`, `icsUrl`, plugin `api_key`/`api_secret`) lives in one file, `~/.local/state/noctalia/settings.toml`. That file is never committed in the clear: `noctalia/settings.toml` is gitignored and only the SOPS-encrypted `noctalia/settings.sops.toml` is tracked. The age private key at `~/.config/sops/age/keys.txt` must be backed up outside this repo, or the encrypted file is unrecoverable.
