# dotfiles — `machine/workforce`

Dotfiles for **workforce** (ThinkPad T490), Debian sid + KDE Plasma, light theme. Managed with [GNU Stow](https://www.gnu.org/software/stow/) — one top-level directory per app, mirroring `$HOME`.

## Use

```sh
git clone <remote> ~/dotfiles && cd ~/dotfiles
git switch machine/workforce

stow zsh ghostty tmux nvim k9s hypr noctalia btop fish starship
# or a single package:
stow ghostty
```

Re-run `stow <pkg>` after pulling changes to relink. `stow -D <pkg>` removes the symlinks.

## Packages

`zsh` `fish` `starship` `nvim` `ghostty` `tmux` `k9s` `btop` `hypr` `noctalia`

## Branch rules

- **Don't merge `main` into this branch.** `main` and `workforce` have diverged (different hypr/noctalia/zsh/ghostty configs) — cherry-pick specific commits across instead.
- Fresh-install steps live in `Debian Sid — Plasma Install Runbook.md`.
- Deeper context for AI assistants (current work, decisions, gotchas) is in `CLAUDE.md` / `AGENTS.md`.
