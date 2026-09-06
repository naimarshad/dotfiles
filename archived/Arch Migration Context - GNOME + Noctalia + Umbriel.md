---
title: "Arch Migration Context: GNOME + Noctalia + Umbriel"
aliases: ["Arch Migration Context", "Umbriel vs niri"]
tags: [arch, gnome, noctalia, umbriel, niri, migration, context, thinkpad-t490]
machine: "ThinkPad T490 (20N2004AGE)"
status: "context / not started"
supersedes-candidate: "Debian Testing - GNOME Install Runbook.md"
---

# Arch migration context

**This is not a runbook. It is the context a future session needs** to turn `Debian Testing - GNOME Install Runbook.md` (Rev 4) into an Arch equivalent, plus the Umbriel-vs-niri decision that has to be made before any of it is written.

Nothing here has been executed. The Debian machine described in Rev 4 is the currently running system.

## Target stack

| Layer | Debian (current) | Arch (proposed) |
|---|---|---|
| Base | debootstrap `testing` | `pacstrap` (or `archinstall`) |
| Init / boot | systemd + systemd-boot | unchanged |
| Filesystem | btrfs + snapper, `@ @home @log @snapshots` | unchanged |
| Initramfs | `initramfs-tools`, `MODULES=dep` | `mkinitcpio` (different hooks, same job) |
| Desktop (fallback) | `gnome-core` | `gnome` / `gnome-shell` + `gdm` |
| Shell | Noctalia 5 (apt, `pkg.noctalia.dev`) | Noctalia 5 (distro repo or AUR) |
| Compositor | niri, **built from source** | **decision pending: niri (packaged) vs Umbriel** |
| Display manager | greetd + noctalia-greeter | unchanged |

## The batteries that carry over unchanged

These are OS-agnostic and should be lifted from Rev 4 almost verbatim. They are the majority of the runbook:

- **Disk + btrfs spine** (Steps 02-03): GPT, 1 GiB ESP, `mkfs.btrfs -L debian`, the four subvolumes, `compress=zstd:3,noatime`. Identical.
- **systemd-boot** (Step 07): `bootctl install`, `/etc/kernel/cmdline` with `root=UUID=… rootflags=subvol=@`. Arch does this via `mkinitcpio` + a `.preset`, but the cmdline requirement and the failure mode (emergency shell) are the same.
- **Snapper** (Step 16): identical, **including the danger callout**. The silent `create-config` failure documented in Rev 4 is not Debian-specific; carry that verification block over unchanged.
- **The whole dev-tooling layer** (Steps 18-22): zsh + oh-my-zsh + Powerlevel10k + mise, Docker, kubectl, sops/age, qemu/libvirt, Zed, Claude Desktop/Code, syncthing. Only the package manager line changes; on Arch most of these move from "third-party repo" or "upstream release binary" into plain `pacman`/AUR, which *shortens* these steps.
- **Dotfiles + stow** (Step 15): unchanged. `ghostty zsh nvim tmux` are compositor-agnostic.
- **Noctalia config + SOPS** (Step 17i): unchanged. Config lives at `~/.local/state/noctalia/`, tracked as `noctalia/settings.sops.toml`, age key at `~/.config/sops/age/keys.txt`. Nothing about this is distro-specific.
- **Theming** (Step 12): `qt6ct`, Bibata cursors, adw-gtk3. All three are in Arch repos or AUR, so the adw-gtk3 source build and the standalone dart-sass dance both disappear. **The gsettings half still applies** and is still the part that silently does nothing if skipped.

## What genuinely changes

- **Bootstrap:** `pacstrap -K /mnt base linux linux-firmware` instead of `debootstrap`. `genfstab -U /mnt >> /mnt/etc/fstab` replaces the hand-written fstab heredoc, which removes the unquoted-heredoc gotcha in Step 06.
- **Initramfs:** `mkinitcpio` with `MODULES`/`HOOKS` in `/etc/mkinitcpio.conf`. Needs `btrfs` in `MODULES` (or the `btrfs` hook). The Rev 4 ordering trap (edit config before installing the kernel) does not exist in the same form.
- **Third-party lane collapses.** Rev 4 has a whole Step 13 about keyring + deb822 `.sources` + `Signed-By`. On Arch that is `pacman` + AUR helper. `ghostty`, `mise`, `k9s`, `sops`, `kubecolor`, `kubie`, `eza`, `adw-gtk3`, `bibata-cursor-theme` are all packaged. This is the single biggest simplification.
- **No `firmware-linux` / `firmware-iwlwifi` split.** Arch ships `linux-firmware` as one package, so the WiFi trap from Step 07 goes away.
- **Rolling discipline changes shape.** Rev 4's "testing has no security archive, snapshot before upgrading" reasoning is replaced by Arch's: read the news feed before `pacman -Syu`, never partial-upgrade. Snapper matters *more*, not less.

## The decision: Umbriel or niri

### What Umbriel actually is

A Wayland compositor from `noctalia-dev`, the same org as Noctalia. C++23 on wlroots, with `umbrielfx` (a hard fork of SceneFX) for effects. Installed on the current Debian machine at **0.1.0** as a side effect of adding the Noctalia repo, alongside `xdg-desktop-portal-umbriel`. Config is TOML (`~/.config/umbriel/config.toml`) with includes; keybinds are plain key-value (`"Mod+Return" = "spawn:kitty"`). It has its own IPC: `umbriel msg`, `umbriel validate`, and `umbriel subscribe` for a JSON event stream.

### Where Umbriel is genuinely ahead

- **Three layouts** (scrolling, dwindle, master) selectable per workspace. niri is scrolling-only by design.
- **Effects are first-class**: blur, shadows, rounded corners, double borders, animated transitions, animated overview, per-output scratchpads.
- **Same-org as Noctalia**, so the shell and compositor are developed together.
- **TOML config** rather than niri's KDL, which is closer to the rest of this machine's config surface.

### Where niri is genuinely ahead

- **Maturity.** niri is at 26.04 with a long release history. Umbriel's own README says it plainly: *"Umbriel is young and actively evolving. It is usable today, but configuration keys, keybinds, and behavior may change between releases, and rough edges remain."* That is an upstream warning that your config will break, not a third-party opinion.
- **niri is in Arch `extra`** (`extra/niri 26.04-1`). One `pacman -S niri`, no source build, no `resources/` copy dance, no manual `cp` on every version bump. **This deletes runbook Step 17b-17e entirely.**
- **Umbriel is not properly packaged on Arch.** The AUR `umbriel` package is a *placeholder that does not install a functional build*; real installs go through the Noctalia distro repo. So choosing Umbriel on Arch **reintroduces the exact third-lane problem that moving to Arch would otherwise solve.**
- **Noctalia does not need Umbriel.** Noctalia lists niri as a first-class compositor integration alongside Hyprland, Sway, Scroll, Mango, Labwc, Triad, and dwl. The "better integration" argument for Umbriel is softer than it first appears: it is same-org co-development, not exclusive capability.
- **Your niri config already exists and now works.** `binds.kdl`, `outputs.kdl`, `rules.kdl`, `environment.kdl` were audited and fixed this session. Switching to Umbriel means rewriting all of it in TOML, including the 12 Noctalia IPC binds.
- **niri 26.04 already does blur.** `rules.kdl` uses `background-effect { xray true; blur true; noise; saturation }`. The effects gap Umbriel would close is narrower than it was a year ago.

### Honest recommendation

**Go to Arch, stay on niri.** The strongest argument for the Arch move is that it removes the source-build lane, and niri being in `extra` is precisely what delivers that. Picking Umbriel at 0.1.0, from a repo rather than the AUR, spends that win immediately and adds an upstream that warns you its config format will change.

The case for Umbriel is real but it is a *different* case: you want dwindle/master layouts, or you want to be close to the Noctalia project. Neither is a reliability argument.

**A middle path exists and costs nothing:** Umbriel is already installed here and already has a session entry at the greeter. Use it on the current Debian machine for a week before committing to it on a fresh install. If it holds up, the Arch runbook can adopt it with evidence instead of a guess. That is the cheapest way to answer this question properly, and it needs no migration at all.

## Settle before writing the runbook

1. **Compositor**: niri (packaged, known-good config) or Umbriel (0.1.0, config rewrite)? Trial Umbriel on the current machine first.
2. **Install method**: `archinstall` (fast, less control over the btrfs layout) or manual `pacstrap` (mirrors Rev 4's structure)? Manual keeps the two runbooks comparable.
3. **AUR helper**: `paru` or `yay`, and whether AUR counts as a "lane" worth documenting the way Rev 4 documents the `.deb` lane.
4. **Branch**: new machine branch, or reuse `machine/workforce` once the machine is reinstalled? The `niri/` stow package is machine-specific either way.
5. **Kernel**: `linux` or `linux-lts`? Rev 4's rolling-suite caution argues for keeping an LTS fallback entry in systemd-boot.

## Reuse map

When writing the Arch runbook, pull these from Rev 4 with minimal edits: Steps 02, 03, 09, 14, 15, 16, 17a, 17f-2, 17h, 17i, 18, 19c/d, 20, 21, 22, and the Restore checklist. Rewrite Steps 01, 04, 05, 06, 07, 08, 10-13. Delete Steps 17b-17e if niri is chosen (packaged) or rewrite them for the Noctalia repo if Umbriel is.
