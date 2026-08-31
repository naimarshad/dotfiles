# dotfiles

Personal dotfiles for a Wayland desktop built around the [niri](https://github.com/YaLTeR/niri) scrolling compositor and the [Noctalia](https://github.com/noctalia-dev/noctalia-shell) shell, plus the terminal and editor setup that goes with them.

Managed with GNU Stow. Every top-level directory is a Stow package whose contents mirror the path layout under `$HOME`, so `niri/.config/niri/` symlinks to `~/.config/niri/`.

## Packages on this branch

| Package | Symlinks to | What it is |
| --- | --- | --- |
| `niri` | `~/.config/niri/` | Compositor config, split across KDL includes, plus the wallpaper and workspace helper scripts |
| `noctalia` | `~/.config/noctalia/` | Quickshell-based desktop shell: bar, launcher, control centre, colorschemes, plugins |
| `hypr` | `~/.config/hypr/` | Previous Hyprland setup, kept for reference after the niri migration |
| `ghostty` | `~/.config/ghostty/` | Terminal config and keybinds, with the colour theme pinned by hand |
| `nvim` | `~/.config/nvim/` | LazyVim-based Neovim config with a pinned `lazy-lock.json` |
| `zsh` | `~/.zshrc`, `~/.p10k.zsh`, `~/.kube/kubie.yaml` | Oh My Zsh with Powerlevel10k, plus the kubie context switcher config |
| `fish` | `~/.config/fish/` | Fish shell with Starship, fzf bindings, gitnow, and kubecolor wrappers |
| `starship` | `~/.config/starship/` | Helper scripts (`cpu.sh`, `netinfo.sh`) used by custom prompt modules |
| `btop` | `~/.config/btop/` | Resource monitor and its Catppuccin and Noctalia themes |
| `gtk` | `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/` | GTK theme, cursor, font, and the generated Noctalia CSS |
| `fontconfig` | `~/.config/fontconfig/` | Font substitution and rendering rules |

The Starship prompt config itself lives at the repo root in `.config/starship.toml` rather than inside the `starship` package, so `stow starship` deploys only the helper scripts.

## Deploying

Clone to `~/dotfiles`, then stow the packages you want, one at a time:

```bash
git clone git@github.com:naimarshad/dotfiles.git ~/dotfiles
stow -d ~/dotfiles -t "$HOME" niri
stow -d ~/dotfiles -t "$HOME" noctalia
stow -d ~/dotfiles -t "$HOME" ghostty
stow -d ~/dotfiles -t "$HOME" nvim
stow -d ~/dotfiles -t "$HOME" zsh
```

Use `stow -n -v` first for a dry run, and `stow -D` to remove a package's symlinks.

## Machine branches

Machines differ by more than a couple of files, so each one gets its own long-lived branch rather than a set of conditional includes.

- `main` is the shared Hyprland-era base.
- `machine/ri-t-0931` is the primary work machine: niri, a light Catppuccin Latte theme, and a three-output desk at home (HDMI-A-1 ultrawide, DP-1 rotated vertical, eDP-1 laptop panel), plus a Lenovo P34w-20 ultrawide at the office that the dock enumerates as either DP-3 or DP-5.
- `machine/workforce` is a Debian Sid and Plasma machine, and carries `k9s` and `tmux` packages that the other branches do not.

Because the package sets themselves diverge, share code between branches by cherry-picking specific commits rather than merging `main` in wholesale.

## Theming

Noctalia's colorscheme engine is the single source of truth for colours. The active scheme is set in `noctalia/.config/noctalia/settings.json` (`colorSchemes.predefinedScheme`, currently Catppuccin Frappe Blue with `darkMode` off, which selects the scheme's light palette).

From there, Noctalia renders colour templates into the apps listed under `templates.activeTemplates`, which is how `niri/.config/niri/noctalia.kdl`, `gtk/.config/gtk-3.0/noctalia.css`, and `gtk/.config/gtk-4.0/noctalia.css` get their values. Those generated files are committed so a fresh checkout looks right before Noctalia has run once. Edit the scheme, not the generated files.

Ghostty is the exception: it is deliberately not in `activeTemplates`, and pins `theme = "Catppuccin Latte"` in its own config instead. Change the terminal colours there, not through Noctalia.

## Local-only files

These stay out of git, see `.gitignore`:

- `zsh/.kube/config*` and `zsh/.kube/configs/`, so kubeconfigs and their credentials stay on the machine
- `niri/.config/niri/unsplash-key`, the API key used by the rotating wallpaper script
- `noctalia/.config/noctalia/plugins/github-feed/settings.json`, which holds a GitHub token
