---
title: "workforce — Reinstall / Reproduce"
tags: [gentoo, reinstall, gitops, workforce, disaster-recovery]
machine: workforce
pairs-with: "Gentoo Binary-First Runbook.md"
---

# workforce — Reinstall & Reproduce

> [!abstract] What this is
> The **executable recovery plan** for the workforce T490. The full [[Gentoo Binary-First Runbook]] is the *manual bootstrap*; this note is the *declarative restore* that sits on top of it. Together they turn a blank disk back into this exact machine with roughly four commands of real decision-making — the rest is `emerge` doing what your committed config files tell it.

> [!warning] The honest boundary
> This is **not** NixOS. There is no bit-identical guarantee and no atomic whole-system generation. What you get instead: a git-tracked *declaration* of package state (`/etc/portage` + `world`), reproduced by `emerge`, with **btrfs/snapper** as the rollback mechanism. "Reproducible" here means *same declared inputs*, not *same bytes* — unless you also run a pinned personal binhost (see Tier 3 at the bottom).

---

## The mental model

The entire identity of this machine is **~6 config files + one package list + your dotfiles**:

| Artifact | What it declares | Tracked in |
|---|---|---|
| `/etc/portage/make.conf` | CFLAGS, FEATURES (getbinpkg), MAKEOPTS | repo |
| `/etc/portage/binrepos.conf/gentoo.conf` | the x86-64-v3 binhost URI | repo |
| `/etc/portage/package.use/*` | installkernel + systemd `boot` flags | repo |
| `/etc/portage/package.accept_keywords/*` | cosmic unmasks | repo |
| `/etc/portage/package.mask/*` | `rust-source` mask, any version pins | repo |
| `/etc/portage/repos.conf/*` | the cosmic-overlay definition | repo |
| `/var/lib/portage/world` | **every package you explicitly installed** | repo |
| dotfiles (`~/.config`, shell, etc.) | user environment | chezmoi |

`world` is the keystone — it is Gentoo's nearest equivalent to a NixOS `systemPackages` list. Every `emerge` you ran appended to it. Restoring these files and running one `emerge @world` rebuilds the machine.

---

## Split: what is manual vs. declarative

> [!note] Why part of this is irreducibly manual
> Partitioning, stage3, chroot, kernel deploy, and bootloader (**Runbook Phases 01–09**) touch bare hardware and firmware state that no file can capture. NixOS has the same limitation — you still run its installer. Accept ~30–45 min of manual bootstrap; **everything after the base system is declarative.**

- **MANUAL (from the runbook):** Phases **01 → 09** — boot media, disk/btrfs layout, stage3, chroot, Portage bootstrap, kernel, fstab, users, bootloader. Produces a *bootable base system*.
- **DECLARATIVE (this note):** restore committed config + `world`, one emerge, chezmoi apply, re-enable services. Produces *this machine*.

---

## One-time: capture current state into the repo

Run this **now**, on the working machine, so the declaration exists before you ever need it. Commit to the `machine/workforce` branch (host-specific state stays off `main`).

```bash
cd ~/dotfiles
git switch machine/workforce      # or: git switch -c machine/workforce

mkdir -p system/etc-portage
# copy the declarative Portage state (skip generated caches)
cp -r /etc/portage/make.conf                system/etc-portage/
cp -r /etc/portage/binrepos.conf            system/etc-portage/
cp -r /etc/portage/package.use              system/etc-portage/
cp -r /etc/portage/package.accept_keywords  system/etc-portage/
cp -r /etc/portage/package.mask             system/etc-portage/
cp -r /etc/portage/repos.conf               system/etc-portage/ 2>/dev/null || true

# the package list — the single most important file
cp /var/lib/portage/world system/world.txt

# a human-readable record of enabled services + selected profile
systemctl list-unit-files --state=enabled > system/enabled-services.txt
eselect profile show    > system/profile.txt
eselect locale show     >> system/profile.txt

git add system/
git commit -m "workforce: capture portage system state + world"
git push -u origin machine/workforce
```

> [!tip] Keep it current
> Re-run the capture (or just the `cp` of `make.conf`, the `package.*` dirs, and `world`) whenever you meaningfully change system packages — a new tool, a new keyword unmask, a version pin. A stale `world` is the only thing that makes reproduction drift. Consider a monthly habit or a tiny `just capture` / shell alias.

---

## Reproduce: blank disk → this machine

### Step A — Manual bootstrap (Runbook Phases 01–09)

Follow [[Gentoo Binary-First Runbook]] Phases **01 through 09** verbatim. Stop when you have a **bootable base system** with networking, a user, and SSH enabled. Nothing here is automated — it's the hardware-touching part.

> [!tip] Shortcut you already built
> Phase 08 enables `sshd` and Phase 09 hands off to SSH. So after the first reboot you can drive the rest of this from your main machine in `tmux` — exactly the workflow the runbook set up.

### Step B — Declarative restore

From the freshly-booted base system (as your user, with `sudo`):

```bash
# 1. Get the declaration
git clone <your-dotfiles-remote> ~/dotfiles
cd ~/dotfiles && git switch machine/workforce

# 2. Restore Portage state (the whole identity of the box)
sudo cp -r system/etc-portage/*      /etc/portage/
sudo cp    system/world.txt          /var/lib/portage/world

# 3. Re-establish the overlay the config references, then sync + trust anchor
sudo emerge --ask app-eselect/eselect-repository
sudo eselect repository add cosmic-overlay git https://github.com/fsvm88/cosmic-overlay.git
sudo emerge-webrsync
sudo emaint sync -r cosmic-overlay
sudo getuto

# 4. Rebuild EXACTLY the declared world — binaries from the binhost, COSMIC from overlay
sudo emerge --ask --verbose --update --deep --newuse --with-bdeps=y @world
```

> [!note] What `@world` does here
> Because `make.conf` (getbinpkg), `binrepos.conf` (v3 binhost), and the `package.*` files are already in place, this single emerge pulls your entire declared package set — desktop stack, platform tools, fonts — as **binaries**, and compiles only the known exceptions (COSMIC from the overlay, anything with a non-default USE flag). It is the same operation as your weekly update, just starting from an empty install.

### Step C — Services, dotfiles, desktop

```bash
# Re-enable services (cross-check against the captured list)
sudo systemctl enable NetworkManager systemd-timesyncd sshd greetd \
                      power-profiles-daemon upower
# PipeWire is per-user:
systemctl --user enable pipewire pipewire-pulse wireplumber

# User environment
chezmoi init --apply <your-dotfiles-remote>   # or: chezmoi apply if already cloned

# COSMIC session backends were installed via @world; log into COSMIC to verify
```

### Step D — Verify

```bash
findmnt -t btrfs                 # all four subvolumes mounted
bootctl list                     # Gentoo default entry present
qlist -I | wc -l                 # installed package count sane vs. old machine
diff <(sort /var/lib/portage/world) <(sort ~/dotfiles/system/world.txt)  # world matches
fc-match monospace               # fonts restored (JetBrains Mono)
```

If `world` diff is empty and btrfs/boot check out, the machine is reproduced.

---

## Rollback (the NixOS-generation equivalent)

You don't have atomic generations, but you have **snapper**, configured in Runbook Phase 11:

- **Before any risky update:** `sudo snapper -c root create -d "pre <change>"` — the weekly routine already does this.
- **Undo specific files:** `snapper -c root undochange <n>..<m>`
- **Full root rollback (live-USB):** mount the btrfs top level, `mv @ @broken`, `btrfs subvolume snapshot /.snapshots/<n>/snapshot @`, reboot. `@home`/`@snapshots` sit outside `@`, so your data and the snapshots themselves survive.

This is the practical stand-in for "boot the previous generation."

---

## Tier 3 — If you want true determinism later

Tiers above give *same declaration, drifting result* (stable rolls forward). To get *same inputs → same system* — the actual NixOS-like property — add two pins:

1. **Pin the ebuild tree to a git SHA** instead of live rsync (Gentoo supports a git-synced repo; check out a known commit). Freezes *which versions exist*.
2. **Run your own binary package host** — build binpkgs (including COSMIC, compiled once on a fast box like the i9 MacBook or selfhost01) and publish them; point `binrepos.conf` at it with top priority. Freezes *which bytes you install* and means COSMIC never compiles on the T490 again.

Together, a tree-SHA + personal binhost make *your* infrastructure the pinned derivation source — reproducibility reached through Gentoo's own primitives. It's real infrastructure to run (a scheduled container on selfhost01), but it's exactly the kind you already operate, and it's the only path that closes the drift gap.

> [!tip] Pragmatic verdict
> **Tiers 1–2 (this note) are the afternoon's-work 90% solution** — commit files you already have, and a disk failure becomes an inconvenience, not a rebuild-from-memory. **Tier 3 is opt-in** for when a fleet or true pinning justifies running the binhost. Start with Tier 1; let Tier 3 fall out of the homelab binhost if you build one anyway.

---

> [!quote] Pairs with
> [[Gentoo Binary-First Runbook]] — the manual bootstrap (Phases 01–09) this restore sits on top of.
