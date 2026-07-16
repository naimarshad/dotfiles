---
title: "Gentoo Binary-First Runbook"
tags: [gentoo, linux, runbook, cosmic, workforce]
machine: workforce
revision: "Rev. 18 — 2026-07-15"
---

# Gentoo without the compile tax

> [!abstract] Overview
> A step-by-step install runbook following the official AMD64 Handbook, tuned for one goal: a minimal, stable, systemd Gentoo that pulls signed binary packages from the official Gentoo binhost and only compiles when you deliberately step outside the envelope.

| Field | Value |
|---|---|
| TARGET | ThinkPad T490 · i7-8565U · 40 GB (workforce) |
| PROFILE | default/linux/amd64/23.0/desktop/systemd |
| BINHOST | x86-64-v3 |
| KERNEL | gentoo-kernel-bin |
| DE | COSMIC (minimal) |

## Contents

- [[#00 — Strategy & ground rules|00 · Strategy & ground rules]]
- [[#01 — Boot media & stage3|01 · Boot media & stage3]]
- [[#02 — Disk & filesystems|02 · Disk & filesystems]]
- [[#03 — Extract stage3 & chroot|03 · Extract stage3 & chroot]]
- [[#04 — Portage: make.conf & binhost|04 · Portage: make.conf & binhost]]
- [[#05 — Sync, profile, trust anchor, @world|05 · Sync, profile, trust anchor, @world]]
- [[#06 — Timezone & locale|06 · Timezone & locale]]
- [[#07 — Kernel — prebuilt, zero compiling|07 · Kernel — prebuilt, zero compiling]]
- [[#08 — fstab, hostname, network, users|08 · fstab, hostname, network, users]]
- [[#09 — Bootloader & first boot|09 · Bootloader & first boot]]
- [[#10 — COSMIC — minimal session, no bundled apps|10 · COSMIC — minimal session, no bundled apps]]
- [[#11 — Fonts & rendering|11 · Fonts & rendering]]
- [[#12 — Maintenance routine|12 · Maintenance routine]]
- [[#13 — What will still compile — honest ledger|13 · What will still compile — honest ledger]]

## 00 — Strategy & ground rules

Since the 23.0 profiles, Gentoo publishes **signed binary packages for the entire stable amd64 tree** — Plasma, GNOME, LibreOffice, Docker, toolchains, everything. Portage transparently prefers a binary package when one matches, and falls back to source only when it doesn't. Your job during install and forever after is simply to **stay inside the envelope the binhost builds for**.

> [!tip] Rule 1 — Stay on stable
> No global `ACCEPT_KEYWORDS="~amd64"`. The binhost only builds stable. Unmask testing packages individually in `package.accept_keywords` and accept that those few compile.

> [!tip] Rule 2 — Default USE flags
> Any USE flag you change away from the profile default forces a local build for that package (Portage respects USE exactly). Touch `package.use` surgically, never globally.

> [!tip] Rule 3 — Generic CFLAGS
> No `-march=native`, no `cpuid2cpuflags` / `CPU_FLAGS_X86`. The v3 binhost already gives you AVX2-level optimization; custom flags just evict you from binary coverage.

> [!tip] Rule 4 — Dist-kernel, prebuilt
> `sys-kernel/gentoo-kernel-bin` is a fully supported, signed, prebuilt kernel with initramfs. Zero kernel compiles, ever.

Every step below is tagged: `[BIN]` downloads binaries, `[CFG]` is pure configuration, `[SRC]` compiles something (there are almost none).

> [!note] The one deliberate exception: COSMIC compiles
> COSMIC ships via the `fsvm88/cosmic-overlay` (`cosmic-base/*`, `cosmic-de/*`), keyworded `~amd64` — and it's Rust, so it's the single big source build in this setup. Phase 10 contains the two mitigations: pull the Rust *toolchain* as `dev-lang/rust-bin` from the binhost (never compile rustc itself), and install only the core session packages instead of the app-laden `cosmic-meta`. Everything else in the system stays binary.

## 01 — Boot media & stage3

Any live environment works — the Gentoo LiveGUI, or even a CachyOS/Arch ISO you already have (it has all the tools: `gdisk`, `mkfs`, `tar`, `chroot`). Boot it in **UEFI mode** and get online.

Download the stage3 that matches the profile — **desktop | systemd**. On the live system:

*`live environment`*
```bash
# Confirm UEFI boot (directory must exist)
ls /sys/firmware/efi/efivars >/dev/null && echo UEFI

cd /tmp
# Grab latest stage3-amd64-desktop-systemd from a mirror:
# https://www.gentoo.org/downloads/  →  "Stage archives" → amd64 → desktop profile | systemd
wget https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd/stage3-amd64-desktop-systemd-*.tar.xz
wget https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd/stage3-amd64-desktop-systemd-*.tar.xz.asc
```

Verify the signature if your live env has `gpg` (Gentoo release key fingerprint is on the downloads page). On an Arch live ISO: `gpg --auto-key-locate=clear,nodefault,wkd --locate-key releng@gentoo.org` then `gpg --verify *.asc`.

## 02 — Disk & filesystems

Minimal UEFI layout: one 1 GiB ESP (doubles as `/efi` for systemd-boot) and one root partition. Skip swap partitions — use a swapfile or zram later if you want hibernate/compressed swap. Adjust `/dev/nvme0n1` to your target disk.

> [!warning] This wipes the disk
> Double-check with `lsblk` before running. If you're keeping CachyOS and dual-booting, create partitions in free space instead of running the destructive `gdisk` sequence below, and reuse the existing ESP.

*`live environment`*
```bash
gdisk /dev/nvme0n1
#  o        → new empty GPT
#  n, 1, default, +1G,  ef00   → EFI System Partition
#  n, 2, default, default, 8300 → Linux root (rest of disk)
#  w        → write

mkfs.vfat -F32 -n EFI /dev/nvme0n1p1
mkfs.btrfs -L gentoo /dev/nvme0n1p2

# Create the flat subvolume layout, then remount by subvolume
mkdir -p /mnt/gentoo
mount /dev/nvme0n1p2 /mnt/gentoo
btrfs subvolume create /mnt/gentoo/@
btrfs subvolume create /mnt/gentoo/@home
btrfs subvolume create /mnt/gentoo/@log
btrfs subvolume create /mnt/gentoo/@snapshots
umount /mnt/gentoo

mount -o subvol=@,compress=zstd:3,noatime /dev/nvme0n1p2 /mnt/gentoo
mkdir -p /mnt/gentoo/{efi,home,var/log,.snapshots}
mount -o subvol=@home,compress=zstd:3,noatime      /dev/nvme0n1p2 /mnt/gentoo/home
mount -o subvol=@log,compress=zstd:3,noatime       /dev/nvme0n1p2 /mnt/gentoo/var/log
mount -o subvol=@snapshots,compress=zstd:3,noatime /dev/nvme0n1p2 /mnt/gentoo/.snapshots
mount /dev/nvme0n1p1 /mnt/gentoo/efi
```

Why this layout: `@` is what snapper snapshots; `@home`, `@log`, and `@snapshots` live *outside* it so a root rollback never touches your data, doesn't drag gigabytes of logs into every snapshot, and — critically — never deletes the snapshots themselves. `zstd:3` compression is the sweet spot on NVMe: transparent, and Portage trees compress extremely well. The `gentoo-kernel-bin` dist-kernel ships btrfs and dracut handles the subvolume root automatically — no extra kernel work.

## 03 — Extract stage3 & chroot

*`live environment`*
```bash
cd /mnt/gentoo
tar xpvf /tmp/stage3-amd64-desktop-systemd-*.tar.xz --xattrs-include='*.*' --numeric-owner

# DNS into the chroot
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

# Mount pseudo-filesystems
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys  /mnt/gentoo/sys  && mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev  /mnt/gentoo/dev  && mount --make-rslave /mnt/gentoo/dev
mount --bind  /run  /mnt/gentoo/run  && mount --make-slave  /mnt/gentoo/run

chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"
```

Everything from here to Phase 09 runs **inside the chroot**.

## 04 — Portage: make.conf & binhost

This phase is the heart of the whole setup. Replace `/etc/portage/make.conf` with:

*`/etc/portage/make.conf`*
```bash
# Generic flags — REQUIRED for binhost matching. Never add -march=native.
COMMON_FLAGS="-O2 -pipe"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

# For the rare source fallback: i7 8th gen = 4c/8t → -j8; 40 GB RAM means no OOM worries
MAKEOPTS="-j8"

# Binary-first: always try binpkgs, verify signatures, parallel downloads
FEATURES="getbinpkg binpkg-request-signature parallel-fetch"
EMERGE_DEFAULT_OPTS="--jobs=4 --load-average=8"

# Accept all licenses (covers firmware/microcode redistributable licenses).
# Tighten to "@FREE" later if you prefer the Gentoo default stance.
ACCEPT_LICENSE="*"

GRUB_PLATFORMS="efi-64"
LC_MESSAGES=C.utf8
```

### Point Portage at the x86-64-v3 binhost

The stage3 ships a `binrepos.conf` pointing at the baseline `x86-64` packages. Your T490's i7-8565U (Whiskey Lake) has AVX2/FMA/BMI2 — everything x86-64-v3 requires — so use the **x86-64-v3** repo: same coverage, better-optimized binaries. Verify capability first, then switch:

*`chroot`*
```bash
# Must print "x86-64-v3 (supported, searched)" — note /lib64, the loader is 64-bit
/lib64/ld-linux-x86-64.so.2 --help | grep -E 'x86-64-v[234]'

# Path-independent fallback: all three flags present = v3-capable
grep -m1 -o 'avx2\|fma\|bmi2' /proc/cpuinfo | sort -u
```

Recent stage3 tarballs ship the binhost pre-configured at `/etc/portage/binrepos.conf/gentoo.conf` — baseline `x86-64`, signature verification already enabled. Don't add a second file; retarget the shipped one to v3:

*`chroot`*
```bash
sed -i 's|x86-64$|x86-64-v3|' /etc/portage/binrepos.conf/gentoo.conf

# Confirm: sync-uri ends in .../23.0/x86-64-v3, verify-signature = true
cat /etc/portage/binrepos.conf/gentoo.conf
```

> [!note] If your stage3 has no binrepos.conf
> Older stages didn't ship it — in that case create `/etc/portage/binrepos.conf/gentoo.conf` with: `[gentoo]`, `priority = 1`, `sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3`, `location = /var/cache/binhost/gentoo`, `verify-signature = true`. Either way, exactly one binhost entry should exist.

> [!note] Why not v4?
> The official binhost doesn't publish x86-64-v4, and it wouldn't help anyway — v4 requires AVX-512, which Whiskey Lake doesn't have. v3 is exactly the ceiling of this CPU, and it's the same feature level CachyOS built its reputation on for its v3 repos, so you lose nothing in that comparison.

## 05 — Sync, profile, trust anchor, @world

*`chroot`*
```bash
# Snapshot sync of the ebuild repository (fast first sync)
emerge-webrsync

# Select the profile matching your stage3 and the binhost coverage
eselect profile list
eselect profile set default/linux/amd64/23.0/desktop/systemd

# Set up the OpenPGP trust anchor for signed binpkg verification
getuto

# Bring the system to current stable — watch the output:
# lines should read [binary ...], not [ebuild ...]
emerge --ask --verbose --update --deep --newuse @world
```

That last command is your first real proof of the setup: on a correctly configured system nearly every line is `[binary U ]`. If you see a wall of `[ebuild]` lines, stop and re-check Phase 04 — usually a typo in `binrepos.conf` or a missed `FEATURES` line.

## 06 — Timezone & locale

*`chroot`*
```bash
ln -sf ../usr/share/zoneinfo/Europe/Berlin /etc/localtime

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set en_US.utf8
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
```

## 07 — Kernel — prebuilt, zero compiling

With `USE=systemd-boot`, the kernel's install hook runs systemd's `kernel-install`, which requires the machine-id and an initialized ESP *before* the kernel is emerged — so the bootloader groundwork happens here, not later:

*`chroot`*
```bash
# Prerequisites for kernel-install: mounted ESP, machine-id, sd-boot, cmdline
findmnt /efi                 # must show the vfat ESP; if not: mount /dev/nvme0n1p1 /efi
systemd-machine-id-setup
bootctl install              # creates /efi/EFI/systemd + /efi/loader/

# kernel-install refuses to run in a chroot without an explicit cmdline
# (it would otherwise copy the LIVE system's /proc/cmdline — wrong root!).
# rootflags=subvol=@ is mandatory for the btrfs layout from Phase 02.
mkdir -p /etc/kernel
echo "root=UUID=$(blkid -s UUID -o value /dev/nvme0n1p2) rootflags=subvol=@ rw" > /etc/kernel/cmdline
cat /etc/kernel/cmdline      # verify: your btrfs UUID + subvol=@
```

Now configure `installkernel` and pull the kernel — the boot entry gets written automatically on install:

*`chroot`*
```bash
# installkernel integration: systemd-boot + dracut initramfs handling.
# systemd-boot support requires systemd itself built with USE=boot (bootctl + sd-boot).
mkdir -p /etc/portage/package.use
cat <<'EOF' > /etc/portage/package.use/installkernel
sys-kernel/installkernel systemd-boot dracut
sys-apps/systemd boot
EOF

# Firmware + microcode (licenses already accepted via ACCEPT_LICENSE)
emerge --ask sys-kernel/linux-firmware

# Intel microcode (T490 = Intel, no ambiguity)
emerge --ask sys-firmware/intel-microcode

# The prebuilt, signed distribution kernel with initramfs
emerge --ask sys-kernel/gentoo-kernel-bin
```

> [!note] The honest cost of systemd-boot
> The `sys-apps/systemd boot` flag is a non-default USE change, so systemd rebuilds from source — ~10–15 min on the T490, and again on each future systemd version bump (a handful of times a year, runs fine in the background). Also expect `gentoo-kernel-bin` and `linux-firmware` to appear as `[ebuild]`: neither compiles anything — the kernel unpacks prebuilt and generates the initramfs locally; firmware is a fetch-and-copy. If binary purity matters more than a two-file boot chain, `installkernel[grub]` keeps everything on the binhost instead.

## 08 — fstab, hostname, network, users

Don't hand-copy UUIDs — let the shell substitute them. An **unquoted** heredoc (`<<EOF`, no quotes) expands the `$(blkid ...)` calls at write time, so the file lands with real UUIDs baked in:

*`chroot`*
```bash
ROOTDEV=/dev/nvme0n1p2   # btrfs partition
ESPDEV=/dev/nvme0n1p1    # EFI System Partition

cat > /etc/fstab <<EOF
# ── Gentoo btrfs: one filesystem, four subvolume mounts ────────────
UUID=$(blkid -s UUID -o value $ROOTDEV)  /            btrfs  subvol=@,compress=zstd:3,noatime           0 0
UUID=$(blkid -s UUID -o value $ROOTDEV)  /home        btrfs  subvol=@home,compress=zstd:3,noatime       0 0
UUID=$(blkid -s UUID -o value $ROOTDEV)  /var/log     btrfs  subvol=@log,compress=zstd:3,noatime        0 0
UUID=$(blkid -s UUID -o value $ROOTDEV)  /.snapshots  btrfs  subvol=@snapshots,compress=zstd:3,noatime  0 0

# ── ESP (shared with other OSes on dual-boot — never format) ───────
UUID=$(blkid -s UUID -o value $ESPDEV)  /efi  vfat  umask=0077  0 2
EOF

# Validate: parses fstab, resolves every UUID, checks fs types — no mounting
findmnt --verify --fstab
```

`findmnt --verify` must report **0 parse errors, 0 errors**. A warning about "systemd still uses the old version / daemon-reload" is safe to ignore in the chroot — it addresses the live system's systemd, not the one that boots this fstab.

> [!note] Pre-existing partitions on a shared disk
> Append lines per partition you actually want at boot, with two habits: give non-essential data partitions `nofail` (a failed mount then degrades to a missing directory instead of dropping boot into emergency mode — e.g. `UUID=... /backup ext4 defaults,noatime,nofail 0 2`, plus `mkdir /backup`), and reuse an existing swap partition as-is (`UUID=... none swap sw 0 0`). Leave Windows NTFS partitions *out* of fstab entirely: auto-mounting them risks touching a hibernated Windows filesystem — mount ad hoc with `mount -t ntfs3` on the rare occasion you need files from them.

*`chroot`*
```bash
echo workforce > /etc/hostname
# machine-id already created in Phase 07 (kernel-install needed it)
systemd-firstboot --prompt 2>/dev/null || true

# Networking + essentials — all from the binhost
emerge --ask net-misc/networkmanager app-admin/sudo app-shells/zsh app-misc/tmux dev-vcs/git sys-fs/btrfs-progs
# No extra editor — stage3 ships nano, and your real editor (Zed) comes later as Flatpak if wanted

systemctl enable NetworkManager
systemctl enable systemd-timesyncd

# SSH — openssh ships in stage3's @system, nothing to emerge.
# Enabling it now means Phases 10–11 can be driven remotely after reboot.
systemctl enable sshd

# root password + your user
passwd
useradd -m -G wheel,audio,video,usb -s /bin/zsh naeem
passwd naeem
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
```

## 09 — Bootloader & first boot

systemd-boot was installed back in Phase 07 (it had to precede the kernel), and `kernel-install` wrote the boot entry when the kernel deployed — so this phase is verification and the jump:

*`chroot`*
```bash
# Entry present? Should list 6.18.x-gentoo-dist-bin
bootctl list

# If the entry is missing, redeploy the kernel:
#   emerge --config sys-kernel/gentoo-kernel-bin

exit                       # leave chroot
umount -R /mnt/gentoo
reboot
```

> [!note] Continue over SSH
> After first boot, log in once at the console to get online and grab the address — `nmcli device wifi connect "<ssid>" password "<pw>"` then `ip -4 -brief addr` — and from there run Phases 10–11 from your main machine: `ssh naeem@<ip>`, start `tmux`, kick off the COSMIC emerge inside it. If the SSH connection drops mid-compile, `tmux attach` resumes it untouched. Once chezmoi has applied your dotfiles, switch to key-based auth and set `PasswordAuthentication no` in `/etc/ssh/sshd_config`.

If it boots to a login prompt with working networking (`nmcli device wifi connect ...`), the base install is done and you have compiled approximately nothing.

## 10 — COSMIC — minimal session, no bundled apps

COSMIC is **not** in the main Gentoo tree — it ships via [fsvm88's cosmic-overlay](https://github.com/fsvm88/cosmic-overlay), the install path referenced by both the Gentoo wiki and upstream cosmic-epoch. It's an unofficial overlay (AUR-comparable trust level) but with CI-based QA and vendored, pinned dependency tarballs, so Rust builds don't fetch crates from the network at emerge time. Its packages use the `cosmic-base/*` and `cosmic-de/*` categories. Two rules keep this build small and as binary as possible: get the Rust toolchain prebuilt, and skip `cosmic-meta` (it drags in the whole app suite — editor, terminal, store, player — none of which you want).

### Step 1 — Rust toolchain from the binhost

Rust is COSMIC's build dependency and by far the most expensive thing to compile on a laptop. Pull the prebuilt one *before* anything COSMIC so Portage satisfies `virtual/rust` with it:

*`workforce`*
```bash
emerge --ask dev-lang/rust-bin

# Belt and suspenders: never let the source rustc sneak in
echo "dev-lang/rust" > /etc/portage/package.mask/rust-source
```

### Step 2 — Add the overlay, unmask, install the core session

*`workforce`*
```bash
# Add and sync the overlay (git is already installed from Phase 08)
emerge --ask app-eselect/eselect-repository
eselect repository add cosmic-overlay git https://github.com/fsvm88/cosmic-overlay.git
emaint sync -r cosmic-overlay

emerge --search cosmic-session    # categories now resolve; note the version
```

Unmask the **release** versions per-category (never the `**` live-ebuild form — mixing live and release COSMIC components causes ABI mismatches and a session that won't start):

*`workforce`*
```bash
cat <<'EOF' > /etc/portage/package.accept_keywords/cosmic
cosmic-base/* ~amd64
cosmic-de/* ~amd64
EOF

# Core session ONLY — no cosmic-meta, no cosmic-edit/term/store/player.
# NOTE: components live under cosmic-base/ in this overlay.
# List the overlay's package set first to confirm names + version:
#   ls /var/db/repos/cosmic-overlay/cosmic-base/
emerge --ask cosmic-base/cosmic-session \
             cosmic-base/cosmic-settings \
             cosmic-base/cosmic-greeter \
             cosmic-base/xdg-desktop-portal-cosmic

# Sanity check afterwards: nothing app-shaped slipped in
qlist -I | grep -E 'cosmic-(edit|term|store|player|files)' || echo "clean — no bundled apps"
```

> [!note] Expect one long coffee break — or an overnight run
> This is the single big compile of the whole install. On the T490's i7-8565U (4c/8t U-series), a Rust workspace this size is realistically **2–4 hours** — kick it off before dinner. Your 40 GB RAM is the silver lining: `-j8` runs without any swap pressure. It happens once; subsequent COSMIC version bumps rebuild only what changed. Before confirming the `--ask` list, scan it: if `dev-lang/rust` (not `rust-bin`) appears, Step 1 didn't take.

> [!note] Overlay quirks worth knowing
> The overlay may pull `dev-util/dart-sass-bin`; if a conflict with `dev-ruby/sass` ever appears, prefer the overlay's `dart-sass-bin`. Feature releases (e.g. 1.3's Frosted Glass) reach the overlay days after upstream tags them — `emaint sync -r cosmic-overlay` in your weekly routine and the version bump delivers them; never reach for live ebuilds to get a feature early.

> [!warning] If Portage pulls cosmic-files as a hard dependency
> Some COSMIC components declare the file manager as a runtime dep of the session. If it appears in the `--ask` list as unavoidable, let it in — it's small — and keep Nemo (`gnome-extra/nemo`, stable, `[BIN]`) as your actual file manager. Don't fight hard dependencies with masks; that's how sessions break.

### Step 3 — greetd login manager

`cosmic-greeter` fronts `greetd`, the minimal option (no SDDM/GDM stack):

*`/etc/greetd/config.toml`*
```ini
[terminal]
vt = 7

[default_session]
command = "/usr/bin/dbus-run-session /usr/bin/cosmic-comp /usr/bin/cosmic-greeter"
user = "cosmic-greeter"
```

*`workforce`*
```bash
emerge --ask gui-libs/greetd
systemctl enable greetd
```

### Step 4 — Session backends: audio & power

COSMIC's Sound and Power panels are frontends — they need backend daemons that COSMIC doesn't pull in itself. Without them the audio output dropdown is empty and Power mode shows "Backend not found". Both are stable/binary:

*`workforce`*
```bash
# Audio — PipeWire + session manager. Runs PER-USER, not system-wide.
emerge --ask media-video/pipewire media-video/wireplumber
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# CPU power profiles (Battery/Balanced/Performance in the Power panel)
emerge --ask sys-power/power-profiles-daemon
systemctl enable --now power-profiles-daemon

# Verify audio server is up (after a re-login if the --user line was fresh)
pactl info | grep 'Server Name'
```

> [!note] The per-user gotcha
> PipeWire is a *user* service — `systemctl --user`, not system-wide. If the Sound panel still shows no output device, log out and back in so the session picks up the user units, then re-check. Power-profiles-daemon, by contrast, is a system service.

### Step 5 — Your actual apps

Terminal, browser, file manager — your stack, not COSMIC's. Zen isn't packaged in Gentoo, and the Flatpak Ghostty keeps another Zig/GTK build off your plate:

*`workforce`*
```bash
# From the binhost — all stable
emerge --ask gnome-extra/nemo app-admin/chezmoi

# zsh is already your login shell (Phase 08: useradd -s /bin/zsh).
# COSMIC apps that spawn a terminal should point at Ghostty in
# Settings → Default Applications once logged in.

emerge --ask sys-apps/flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub app.zen_browser.zen com.mitchellh.ghostty
```

Then `chezmoi init && chezmoi apply` and your zsh/Ghostty/theming config lands exactly as on CachyOS.

## 11 — Fonts & rendering

A stage3 ships almost no fonts, so this is what makes text actually readable — GUI, terminal, TTY, and non-Latin scripts. Every package below is verified in the main `::gentoo` tree and **stable amd64** (binary from the binhost, no overlay, no keyword unmask): jetbrains-mono 2.304, symbols-nerd-font 3.4.0, sil-arabicfonts 3.000, terminus-font 4.49.1.

### Step 1 — Install the fonts

*`workforce`*
```bash
# Programming font + universal Nerd-glyph fallback + Arabic naskh + TTY font
emerge --ask \
  media-fonts/jetbrains-mono \
  media-fonts/symbols-nerd-font \
  media-fonts/sil-arabicfonts \
  media-fonts/terminus-font \
  media-libs/fontconfig media-libs/freetype

# Confirm what actually landed (family names must match exactly in config below)
fc-list | grep -iE 'jetbrains|nerd|scheherazade'
```

> [!note] Why symbols-nerd-font instead of a patched font
> Gentoo's `jetbrains-mono` is upstream JetBrains Mono only — it does *not* bundle the Nerd Font-patched variant. Rather than chase a patched font, install the symbols-only `symbols-nerd-font` and register it as a fontconfig *fallback* (Step 3). Then *every* monospace font you use — JetBrains Mono, Ghostty's font, whatever — gets Nerd glyphs, with no per-font patching. Cleaner and more maintainable. Base Arabic UI text is already covered by `media-fonts/noto` from Phase 08; `sil-arabicfonts` adds Scheherazade, a proper naskh reading face.

### Step 2 — Console (TTY) font

The kernel console (Ctrl+Alt+F2…) uses its own bitmap fonts — fontconfig does not apply there. Terminus ships console faces from 12 to 32px, ideal for the 1920×1080 panel. The systemd font name is a **filename** in `/usr/share/consolefonts/` without suffix, and the real Terminus console names are `ter-v`-prefixed (e.g. `ter-v24n`, `ter-v28b`) — **not** the X11-style `ter-118n`. List and test before committing:

*`workforce`*
```bash
ls /usr/share/consolefonts/ | grep ter-v      # see the real names/sizes
setfont ter-v24n                              # test live; try v28b (bold) for a bigger, crisper TTY
```

Once you've picked a size, make it permanent — systemd reads it from `/etc/vconsole.conf`:

*`/etc/vconsole.conf`*
```ini
KEYMAP=us
FONT=ter-v24n
```

> [!warning] If setfont errors on load
> On some kernel 6.12+ setups `setfont` can report `Unable to load such font with such kernel version` or an `ioctl(KDFONTOP)` error — often a smaller/standard size loads fine where a large one fails, and the message is frequently harmless on a headless/early-boot pass. If a size refuses, pick a nearby one that loads cleanly rather than fighting it.

### Step 3 — Rendering tuning + fontconfig

Enable the recommended rendering presets (all `eselect`, no compiling). The exact list on your system comes from `eselect fontconfig list` — enable the subpixel, slight-hinting, and lcdfilter entries it offers:

*`workforce`*
```bash
eselect fontconfig list                        # see available presets + exact filenames
eselect fontconfig enable 10-sub-pixel-rgb     # RGB subpixel — correct for the T490 IPS panel
eselect fontconfig enable 10-hinting-slight    # modern, minimally-distorted hinting
eselect fontconfig enable 11-lcdfilter-default
```

Then a per-user config that makes the Nerd fallback and Arabic face automatic. Create `~/.config/fontconfig/fonts.conf`:

*`~/.config/fontconfig/fonts.conf`*
```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Default monospace = JetBrains Mono -->
  <alias>
    <family>monospace</family>
    <prefer><family>JetBrains Mono</family></prefer>
  </alias>

  <!-- Nerd symbols as universal fallback for ANY monospace -->
  <match target="pattern">
    <test name="family"><string>monospace</string></test>
    <edit name="family" mode="append"><string>Symbols Nerd Font</string></edit>
  </match>

  <!-- Arabic: prefer Scheherazade for ar-language text -->
  <match target="pattern">
    <test name="lang"><string>ar</string></test>
    <edit name="family" mode="prepend"><string>Scheherazade New</string></edit>
  </match>

  <!-- Global rendering (explicit; complements the eselect presets) -->
  <match target="font">
    <edit name="antialias" mode="assign"><bool>true</bool></edit>
    <edit name="hinting" mode="assign"><bool>true</bool></edit>
    <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
    <edit name="rgba" mode="assign"><const>rgb</const></edit>
    <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
  </match>
</fontconfig>
```

Rebuild the cache and verify the chain resolves as intended:

*`workforce`*
```bash
fc-cache -fv
fc-match monospace                 # → JetBrains Mono
fc-match -s :lang=ar | head -3     # → Scheherazade first
```

> [!note] Two family-name checks that silently bite
> fontconfig edits do nothing if the family string doesn't match exactly. Confirm the Arabic name after install — recent SIL packaging calls it `Scheherazade New`, older just `Scheherazade`; `fc-list | grep -i schehera` shows the truth, edit the config to match. And `rgb` subpixel is correct for the T490 panel and a standard-RGB external monitor; if text ever looks colour-fringed on a BGR display, change that one value to `bgr`. Point Ghostty and Zed at `JetBrains Mono` in their own configs to complete the picture.

## 12 — Maintenance routine

### One-time: snapper setup

snapper (`app-backup/snapper`, stable) gives you automatic timeline snapshots plus manual pre-update ones. One quirk to handle: `create-config` insists on creating its own `.snapshots` subvolume *nested inside* `@` — we immediately swap it for the independent `@snapshots` from Phase 02 so snapshots survive a root rollback:

*`workforce`*
```bash
emerge --ask app-backup/snapper

# @snapshots is already mounted at /.snapshots via fstab — snapper's
# create-config refuses if the path exists, so step it aside first:
umount /.snapshots
rmdir /.snapshots

snapper -c root create-config /      # creates config + its own nested .snapshots subvol

# Swap snapper's nested subvolume for our independent @snapshots
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount /.snapshots
chmod 750 /.snapshots

# Verify: snapshots now live on @snapshots
btrfs subvolume show /.snapshots | head -2

# Tame the timeline — hourly snapshots of a desktop root are noise
snapper -c root set-config TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 \
                           TIMELINE_LIMIT_WEEKLY=4 TIMELINE_LIMIT_MONTHLY=2 \
                           TIMELINE_LIMIT_YEARLY=0

systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
```

> [!note] Rollback, honestly
> With this flat layout, day-to-day recovery is `snapper undochange <n>..<m>` (revert specific files) or `snapper diff` to inspect what an update touched. A *full* root rollback is the boot-a-live-USB move: mount the btrfs top level, `mv @ @broken`, `btrfs subvolume snapshot /.snapshots/<n>/snapshot @`, reboot. Two commands, five minutes, and because `@home`/`@snapshots` sit outside `@`, nothing of yours is touched. openSUSE-style boot-menu rollback needs their default-subvolume machinery and GRUB — not worth the complexity on systemd-boot.

Weekly, or whenever you feel like it — this is a rolling release, but the binhost is rebuilt from **stable**, so it's a calm rolling release:

*`weekly update`*
```bash
# Checkpoint first — makes every update reversible
sudo snapper -c root create -d "pre @world $(date +%F)"

sudo emerge --sync
sudo emerge --ask --verbose --update --deep --newuse --with-bdeps=y @world
sudo emerge --ask --depclean          # remove orphans — keep it minimal
sudo eclean-dist -d && sudo eclean-pkg -d   # purge old distfiles/binpkgs (needs gentoolkit — see below)
sudo emaint sync --auto 2>/dev/null || true
```

- **Read the pretend run.** `--ask` shows you binary vs ebuild before anything happens. An unexpected `[ebuild]` line is a signal: a USE flag drifted, or a package fell out of stable coverage. Investigate with `emerge -pv <pkg>` before accepting.
- **`--with-bdeps=y` is deliberate.** It keeps build-time dependencies (Python build backends, etc.) updated alongside runtime ones. Without it, a Python-target transition can leave build tools stranded and make `--depclean` refuse to run. If depclean ever complains that dependencies can't be resolved, it's protecting you — rerun the update line above, then depclean. It never deletes anything while unresolved.
- **One-time: install gentoolkit.** The `eclean-*` cleanup tools above live in `app-portage/gentoolkit` (stable, binary) — `emerge --ask app-portage/gentoolkit` once. It also brings `equery` (which package owns a file, what depends on X) and `eshowkw` (keyword status) — the tools for verifying a claim before acting on it.
- **News items matter.** Run `eselect news read` when prompted — Gentoo announces breaking changes there, not in a changelog you'll never read.
- **GCC upgrades:** the official binhost deliberately lags new stable GCC versions so its binpkgs stay compatible with systems that haven't upgraded yet — another reason staying on stable defaults keeps you inside the envelope.
- **Downgrades are a feature.** Unlike Arch, old ebuild versions stay in the tree; pinning or rolling back a misbehaving package is a one-line mask in `/etc/portage/package.mask`.

> [!tip] GitOps your /etc/portage — snapshots cover the rest
> Everything that defines this system's package state lives in a handful of plain-text files: `make.conf`, `binrepos.conf/`, `package.use/`, `package.accept_keywords/`, `package.mask/`, plus the `@world` set (`/var/lib/portage/world`). Track them with chezmoi or a git repo — that's your declarative desired state — while snapper covers the imperative reality: git tells you what the system *should* be, a snapshot diff tells you what an update actually *did*. Together that's most of what you wanted from NixOS, without the module-API breakage that drove you off it.

## 13 — What will still compile — honest ledger

| Component | Binary? | Notes |
|---|---|---|
| @system + toolchain | ✅ binhost | gcc, glibc, systemd — all prebuilt and signed |
| Kernel | ✅ gentoo-kernel-bin | Prebuilt with initramfs; auto boot entries via installkernel |
| Mesa, PipeWire, fonts, NetworkManager | ✅ binhost | Stable desktop stack, default USE |
| Docker / Podman, kubectl, Helm, Terraform-adjacent tooling | ✅ binhost | Your platform toolbox is stable-tree and covered |
| Rust toolchain | ✅ rust-bin | Prebuilt from the binhost; source rustc masked |
| COSMIC session | ⚠️ compiles | ~amd64 Rust workspace — the one big build (2–4 h on the T490), once |
| Nemo, chezmoi, CLI tooling | ✅ binhost | Stable tree, default USE |
| Zen, Ghostty | ✅ Flatpak | Kept out of Portage entirely |
| Anything you flip USE flags on | ⚠️ compiles | By design — that's the flexibility you're buying into |

Net result: a from-scratch install where exactly one thing compiles — the COSMIC session, once — and everything else arrives as signed binaries. You still keep everything the blog actually praised: per-package version control, downgrade-ability, patchability via `/etc/portage/patches`, and a system whose entire state is a git-trackable directory.

---

> [!quote] Sources
> Sources: Gentoo Handbook AMD64 · wiki.gentoo.org/wiki/Gentoo_Binary_Host_Quickstart · wiki.gentoo.org/wiki/Binary_package_guide · wiki.gentoo.org/wiki/COSMIC · github.com/fsvm88/cosmic-overlay · gentoo.org/news/2023/12/29/Gentoo-binary.html · Rev. 18 — 2026-07-15
