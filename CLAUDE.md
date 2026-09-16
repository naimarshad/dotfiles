# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Layout

This is a personal dotfiles repo using a **Stow-compatible directory structure**: each top-level package folder mirrors the target path from `$HOME`. For example, `niri/.config/niri/` symlinks to `~/.config/niri/`.

Packages on this branch: `bat`, `btop`, `fish`, `fontconfig`, `ghostty`, `gtk`, `k9s`, `niri`, `noctalia`, `nvim`, `starship`, `tmux`, `zsh`, plus `hypr` (legacy).

To deploy a package: `stow -d ~/dotfiles -t "$HOME" <package>`

## Machine Branches

Shared config lives on `main`. Each machine gets its own long-lived branch, and the package sets themselves diverge, not just a few files:

- `main` is the shared Hyprland-era base, and has no `niri` or `gtk` package.
- `machine/ri-t-0931` is the primary work machine: niri compositor, dark Gruvbox theme, three outputs at home (HDMI-A-1 ultrawide, DP-1 rotated vertical, eDP-1 laptop panel) plus a Lenovo P34w-20 ultrawide at the office.
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

**Colours are generated, not hand-edited.** The scheme is selected in `settings.toml`, and Noctalia renders that palette into every app in its active-template list, producing `niri/.config/niri/noctalia.kdl`, `gtk/.config/gtk-3.0/noctalia.css`, `gtk/.config/gtk-4.0/noctalia.css`, `ghostty/.config/ghostty/themes/noctalia`, `bat/.config/bat/themes/noctalia.tmTheme`, `btop/.config/btop/themes/noctalia.theme` and `nvim/.config/nvim/lua/matugen.lua`. (`hypr/.config/hypr/noctalia/noctalia-colors.conf` is a stale v4 Catppuccin render: hyprland is no longer an active template.) All of those are committed so a fresh checkout looks right before Noctalia first runs. Change the scheme and let it regenerate; hand-editing a generated file is overwritten on the next render. The `gtk` templates are confirmed working under v5: `gtk-4.0/gtk.css` changed from a symlink into `adw-gtk3` to a real file that `@import`s `noctalia.css`, and both `noctalia.css` files regenerate.

Ghostty was brought **inside** that system in the v5 migration (`theme = noctalia`, with Noctalia rendering `ghostty/.config/ghostty/themes/noctalia`), and `machine/workforce` made the same switch in `5a7403e`. This branch briefly left it for a hand-pinned `Gruvbox Dark` terminal (`253959d` through `331bdf6`) and then came back: Ghostty, `bat`, `btop` and Neovim all read the Noctalia render again, and the two tools Noctalia has no template for, `tmux` and `k9s`, carry the same Gruvbox Light hex by hand. See "Key Environment Details" for the per-tool list.

## Neovim Config (`nvim/`)

LazyVim-based. `lua/config/` holds `autocmds.lua`, `keymaps.lua`, `lazy.lua`, and `options.lua`. `lua/plugins/` holds the overrides, including `colorscheme.lua`. Plugin versions are pinned in `lazy-lock.json`.

There is no colorscheme plugin in the usual sense. `colorscheme.lua` loads `RRethy/base16-nvim` and hands LazyVim a `colorscheme` *function* that sets `background=light` and calls `require("matugen").setup()`. `lua/matugen.lua` is Noctalia's nvim render: a base16 palette for the active scheme plus a `SIGUSR1` handler, which Noctalia signals after every re-render so open editors re-theme live. Do not hand-edit `matugen.lua`, and do not add a second colorscheme plugin, since LazyVim would apply it on top.

## tmux (`tmux/`)

`tmux/.config/tmux/tmux.conf` plus `tmux/.config/tmux/scripts/` are tracked. Plugins are TPM-managed and live in `~/.config/tmux/plugins/`, which is gitignored: restore them on a new machine with `prefix + I`.

`TMUX_PLUGIN_MANAGER_PATH` is set to `~/.config/tmux/plugins/` in the config. Without it TPM installs to `~/.tmux/plugins/` instead, which is how this config once ended up with plugins split across two directories and `run` lines pointing at a path that did not exist, silently rendering status modules as empty strings.

**The status line is hand-rolled, not themed by a plugin.** An earlier version used `egel/tmux-gruvbox`, which was dropped because it owns `status-left` and `status-right` outright and exposes only four fixed slots, which is not enough for kube, git, cpu, battery, clock and host together.

The palette lives in `@gb_*` user options and is the Gruvbox Light hex Noctalia renders into `ghostty/themes/noctalia` (background, foreground and palette slots 9-14), copied by hand because Noctalia has no tmux template. It is defined in exactly one place: the scripts read colours back with `tmux show -gqv @gb_<name>` rather than hardcoding hex, so changing a colour in `tmux.conf` changes it everywhere.

Three things here are load-bearing and easy to break:

- **`status-left` and `status-right` are deliberately set without `-F`.** They contain `#{pane_current_path}`, and `-F` would expand it once at parse time instead of per render, permanently freezing `git.sh` to whatever directory the server started in. That is also why those two lines write hex literally while every `*-style` option above them uses `-F` with `@gb_*`.
- **Plugin order matters.** `tmux-cpu` supplies `#{cpu_percentage}` by rewriting `status-right` when it loads, so the plugin list must come after the status line is defined.
- **`git.sh` takes the pane's directory as an argument.** The tmux server's own working directory is wherever it was started, so a script reading `$PWD` reports the wrong repository. Dirtiness uses `git status --porcelain -uno`; skipping untracked files keeps it off the status-interval critical path in large trees.

`scripts/kube.sh` shows `context:namespace` from `kubectl config view --minify`, chosen over parsing `~/.kube/config` so a multi-file `KUBECONFIG` merges correctly. It is offline and never contacts the cluster. A context matching `prod|prd|production` turns the whole segment red, the same guard rail as the `.zshrc` wrappers. Caveat worth remembering: the tmux server has its own environment, so this reflects the kubeconfig's selected context and **not** a kubie subshell's per-shell `KUBECONFIG`.

`scripts/battery.sh` reads sysfs directly, replacing the `tmux-battery` plugin. It treats the ACPI state `Not charging` (on AC, holding at a charge limit) as plugged in, because the naive reading shows a draining icon while the machine is on mains.

`tmux-resurrect` and `tmux-continuum` save every 15 minutes with `@continuum-restore 'off'`: an automatic restore on server start is startling when you wanted a clean session. Restore by hand with `prefix + Ctrl-r`. `tmux-yank` uses `wl-copy`, since no `xclip` or `xsel` is installed.

**Verifying status modules is harder than it looks**, and two separate traps have already cost time here:

- `tmux display -p '#{E:status-right}'` does **not** execute `#()` jobs and always shows them blank, even for `#(echo hello)`.
- Attaching a client under `script` does render them, but tmux repaints only the segments that changed, so grepping the tail of the capture shows a partial line and makes working modules look missing. Grep the whole capture for the value you expect instead of reading the last line.

## Shells

Two shells are configured, with different prompts, so a prompt change usually needs making twice.

**Zsh (`zsh/`)** uses Oh My Zsh with Powerlevel10k:

- `.zshrc` for the plugin list, exports, and aliases
- `.p10k.zsh` for the prompt config, shared across machines
- `.kube/kubie.yaml` for the kubie context switcher
- `.kube/color.yaml` for kubecolor's theme (see "Key Environment Details")

`.zshrc` also carries production guards wrapping `kubectl` and `helm`, which are the most delicate thing in the file. **They are currently commented out** (as of `4b113d5`), with a plain `alias kubectl=kubecolor` in their place, so no confirmation prompt fires today. The description below is of the code as written, kept because re-enabling it is a matter of uncommenting. When the current context matches `_PROD_PATTERN`, a destructive subcommand prompts for confirmation before running. The verb is decided by walking the arguments, skipping anything starting with `-`, and taking the first token that appears in either the read-only or the dangerous list, so `kubectl -n default delete pod` is caught and `helm diff upgrade` is not a false alarm. Read-only is checked first for exactly that reason. Each function re-asserts its patterns with `: "${VAR:=default}"`, because an unset pattern would leave `grep -E` testing an empty regex, which matches everything and would make every command look dangerous. Keep both properties if you touch these.

**Fish (`fish/`)** uses Starship, with fzf key bindings, gitnow, and `kubectl`/`k` wrapped to `kubecolor`. Note that `starship.toml` itself lives at the repo root under `.config/`, not inside the `starship` package.

## Key Environment Details

- **Terminal**: Ghostty (`com.mitchellh.ghostty`), `theme = noctalia` (the Noctalia render at `ghostty/.config/ghostty/themes/noctalia`), font `JetBrainsMono NF Regular`
- **One palette everywhere: Noctalia's Gruvbox Light.** Background `#fbf1c7`, foreground `#3c3836`. The scheme chosen in Noctalia is the single source of truth, for the desktop (niri, GTK, the shell) and for everything inside the terminal alike. Tools with a Noctalia template read the render directly; the rest carry the same hex by hand and must be updated when the scheme changes:
  - rendered by Noctalia: Ghostty (`theme = noctalia`), `bat` (`--theme=noctalia`), `btop` (`color_theme = "noctalia"`), Neovim (`lua/matugen.lua` via base16)
  - hand-copied from the Ghostty render: `tmux` (`@gb_*` options in `tmux.conf`), `k9s` (`skin: gruvbox-light`, `k9s/.config/k9s/skins/gruvbox-light.yaml`), fzf (`FZF_DEFAULT_OPTS` in both `.zshrc` and `config.fish`), and `kubecolor` (`zsh/.kube/color.yaml`, deployed to `~/.kube/color.yaml`)
- **`kubecolor` must use explicit hex, never its presets.** The built-in `light` preset is written in ANSI names (`info: black`, `muted: gray`, `string: yellow`), and Gruvbox remaps those slots: ANSI black is `#fbf1c7`, the background, so default text vanished. `color.yaml` sets every `theme.base.*` colour as hex from the Ghostty render. `KUBECOLOR_PRESET=light` in both shells is only the fallback before that file is stowed; `KUBECOLOR_LIGHT_BACKGROUND` was dropped because it forces the same preset and nothing else.
- **`bat` needs its cache rebuilt** after `themes/noctalia.tmTheme` changes: `bat cache --build`. Otherwise `--theme=noctalia` keeps using the previously compiled copy, or errors if there never was one.
- **`bat` emits no background.** It writes only `38;2;...` foreground sequences, so it inherits Ghostty's background and its theme choice only affects syntax colours. `k9s`, `btop` and `tmux` all paint their own background and therefore have to be matched explicitly.
- **The dark-era files are kept, not deleted.** `k9s/.config/k9s/skins/gruvbox-dark.yaml` (a local edit of `gruvbox-dark-hard.yaml` with the background lifted to `#282828`) and `btop`'s bundled `gruvbox_dark_v2.theme` (the `#282828` variant; `gruvbox_dark.theme` is the hard `#1d2021` one, so the `_v2` suffix is not a typo) are the ones to reach for if the terminal ever goes dark again.
- **Cursor theme**: `Bibata-Modern-Classic` at size 24, set in `niri/environment.kdl` (both the `cursor` block and `XCURSOR_THEME`) and in the GTK settings
- **GTK theme**: `adw-gtk3` with the `Catppuccin-Macchiato` icon theme and `Inter 12`
- **Screenshots**: niri's built-in actions on the `Print` keys (`screenshot`, `Mod+Print` for screen, `Mod+Shift+Print` for window). There is no `HYPRSHOT_DIR` under niri.
- **Niri keybind prefix**: `Mod` is the Super key. Noctalia binds spawn `noctalia msg ...` directly, since KDL has no variable expansion.

## Known Quirks

Worth knowing before assuming something is a bug you introduced:

- `.config/starship.toml` sits at the repo root instead of in `starship/.config/`, so `stow starship` deploys only `cpu.sh` and `netinfo.sh`.
- `ghostty/.config/ghostty/config` sets `background-blur-radius` twice, at 80 and then 60, left over from resolving a merge conflict. Only one value can win. `theme` is set once.
- `tmux/.config/tmux/themes/noctalia.conf` is gitignored and not sourced. It used to be the last line of `tmux.conf`, silently overriding whatever the status line had set, and Noctalia does not currently render anything there anyway. The tmux palette is the hand-copied `@gb_*` block instead.
- The Catppuccin `.tmTheme`, `.theme` and k9s skin files that sit next to the Noctalia renders are unused leftovers, kept only because they are harmless.
- `hypr/.config/hypr/noctalia/noctalia-colors.conf` still holds Catppuccin Latte from v4. Hyprland is legacy and not an active template, so Noctalia never regenerates it.
- Several files have carried committed merge conflict markers in the past. Grep for `<<<<<<<` before committing a resolution. (The worst offender, Noctalia's v4 `settings.json`, is gone with the v5 migration.)

## Secrets

`.gitignore` keeps kubeconfigs (`zsh/.kube/config*`, `zsh/.kube/configs/`) and the Unsplash API key (`niri/.config/niri/unsplash-key`) out of the repo. This is a public repo, so check any new config file for tokens before adding it.

Under Noctalia 5 every plugin credential (the github-feed PAT, `kubeconfigPath`, `icsUrl`, plugin `api_key`/`api_secret`) lives in one file, `~/.local/state/noctalia/settings.toml`. That file is never committed in the clear: `noctalia/settings.toml` is gitignored and only the SOPS-encrypted `noctalia/settings.sops.toml` is tracked. The age private key at `~/.config/sops/age/keys.txt` must be backed up outside this repo, or the encrypted file is unrecoverable.
