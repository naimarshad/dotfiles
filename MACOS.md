# macOS setup (machine/macbook-i9)

Used Intel i9 MacBook, macOS 26 (Darwin 25.6). Homebrew has dropped Intel support, so packages come from three places: MacPorts for native CLI tools, the official mise binary for language runtimes and fast-moving tools, and a few manual installs. Only terminal and CLI configs are ported. The niri, Noctalia, Hyprland, GTK, fontconfig, fish, starship and arch-update packages stay in the repo but are not used here.

## 1. MacPorts

Installed before the port: `bat claude-code eza fzf git neovim tmux`. Install the rest with:

```bash
sudo port install stow k9s kubecolor kubie btop gh mcfly \
  zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search \
  sops age jq ripgrep fd zoxide
```

`/opt/local/bin` and `/opt/local/sbin` are put on PATH by `zsh/.zshrc`. MacPorts has no `powerlevel10k` and no Ghostty.

## 2. mise (official binary)

mise is the official macOS x64 binary at `~/.local/bin/mise`, not a MacPorts package. Install the runtimes and CLIs with:

```bash
mise use -g kubectl helm go node rust python@3.13
```

`python@3.13` matters: the system `python3` is 3.9, and `jaberos/memory_extractor.py` needs 3.10 or newer. Tools the Zed README expects (`shellcheck`, `shfmt`, `yamllint`, `actionlint`, `golangci-lint`, `lazygit`, `hadolint`, `gopls`, `dlv`) come from mise or MacPorts, whichever has them. Check with `port info <name>` or `mise registry`.

## 3. Manual installs

- **oh-my-zsh**: `~/.oh-my-zsh`, plus these clones into `~/.oh-my-zsh/custom`: `themes/powerlevel10k` (romkatv), and `plugins/zsh-completions`, `plugins/zsh-autosuggestions`, `plugins/you-should-use` (the directory name must be `you-should-use`), `plugins/zsh-bat`.
- **omp** (oh-my-pi): installed with its official curl installer into `~/.local/bin`. `.zshrc` only loads its completions if `omp` is on PATH.
- **Fonts**, copied into `~/Library/Fonts` from the official releases: Monaspace v1.400 variable (Ghostty: `Monaspace Neon Var`, `Monaspace Radon Var`), Monaspace v1.400 static OTF (Zed: `Monaspace Neon`) and `Symbols Nerd Font Mono` from the Nerd Fonts `NerdFontsSymbolsOnly` release. Quit and reopen Ghostty and Zed after installing.
- **Ghostty** and **Zed**: the macOS apps.
- **jaberos**: cloned at `~/jaberos`, then `~/jaberos/install.sh` wires the SessionEnd and SessionStart hooks and the `jev` and `memory-recall` skills into `~/.claude`. Needs `jq`, `python3` 3.10 or newer, `go` and `claude` on PATH. See the jaberos README for `~/.claude/memory-extractor.json` (set `machine` to `macbook-i9`, leave `routes` empty) and the `MEMORY.md` freeze guard, which `install.sh` does not add.

## 4. Stow

From the repo root:

```bash
stow zsh nvim tmux k9s btop bat zed ghostty
```

Stow refuses to overwrite a real file, so move an existing `~/.zshrc` or `~/.config/zed/settings.json` aside first. The `zsh` package links `~/.kube` as a directory into the repo, so never commit kubeconfigs from it.

## 5. Theme: Gruvbox Light

| App | Where it is set |
|---|---|
| Zed | `zed/.config/zed/settings.json`, theme `Gruvbox Light` (Light Hard and Light Soft also ship with Zed) |
| Ghostty | `theme = Gruvbox Light` |
| bat | `--theme=gruvbox-light` (built in, no cache build) |
| btop | `color_theme` points at MacPorts' `gruvbox_light.theme` |
| k9s | `skins/gruvbox-light.yaml`, a copy of the dark-hard skin with a light palette |
| tmux | `themes/gruvbox-light.conf`, hand-written; the catppuccin plugin is not used |
| Neovim | `lua/gruvbox_light.lua` (base16 Gruvbox Light via base16-nvim) |

The Noctalia-generated files (`tmux/themes/noctalia.conf`, `nvim/lua/matugen.lua`, the bat and btop `noctalia` themes) stay in the repo for the Linux machines and are not loaded here.

## 6. macOS differences worth knowing

- **tmux status scripts**: `scripts/battery.sh` reads `pmset -g batt` and `scripts/net.sh` reads `route -n get default` plus `networksetup -listallhardwareports` when `uname` is Darwin. The network block shows `Wi-Fi` or the interface name, with no SSID or signal strength. With the Fortinet VPN up it may show the VPN interface name.
- **tmux**: `tmux.conf` has no plugin dependency. The status line is plain tmux formats using `@gv_*` colours from the theme file. Inside a throwaway shell, run `/opt/local/bin/tmux`, because the oh-my-zsh tmux plugin aliases `tmux`.
- **k9s**: it defaults to `~/Library/Application Support/k9s` on macOS, so `.zshrc` exports `K9S_CONFIG_DIR=$HOME/.config/k9s`.
- **Ghostty**: `window-theme` and `freetype-load-flags` are Linux-only keys and are ignored. Add `macos-option-as-alt = true` only if Neovim or tmux bindings need Alt.
- **Zed icons**: `"icon_theme": "Noctalia Icons"` is still in `settings.json`. The extension lives in `zed-noctalia-icons/` on the workforce machine and is not pushed yet, so Zed falls back to its default icons.

## 7. Verify

```bash
command -v claude jq python3 go mise stow kubecolor k9s mcfly
python3 --version
python3 ~/.claude/hooks/memory_extractor.py --resolve-vault "$PWD"
sh ~/.config/tmux/scripts/battery.sh text
sh ~/.config/tmux/scripts/net.sh text
bat --list-themes | grep -i gruvbox
```

Expected: `python3` 3.10 or newer, the vault path `/Users/naeem/Obsidian/Claude/claude-memory`, a battery percentage, `Wi-Fi` or an interface name, and `gruvbox-light` in the bat list.
