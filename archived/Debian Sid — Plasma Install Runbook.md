---
title: "Debian Sid — Plasma Install Runbook"
aliases: ["Debian Runbook", "Sid Runbook", "T490 Debian"]
tags: [debian, sid, unstable, plasma, systemd-boot, btrfs, runbook, thinkpad-t490]
machine: "ThinkPad T490 (20N2004AGE)"
arch: "amd64"
init: "systemd + systemd-boot"
filesystem: "btrfs + snapper"
desktop: "KDE Plasma 6 (Wayland)"
method: "debootstrap"
rev: "1"
---

# Debian Sid — a binary-native daily driver

**Debian unstable**: prebuilt everything, a btrfs + snapper + systemd-boot spine, and native access to the third-party `.deb` ecosystem. Installed by hand with `debootstrap` for full control over the disk layout and bootloader.

> [!info] Legend
> `[!warning]` = a gotcha to get right · `[!success]` = a binary-native win · `[!danger]` = can lock you out / data loss · `[!note]` = info.

> [!success] Binary-native by default
> No stage3, no profiles, no USE flags, no build matching, no overlays. `qtwebengine` is just a `.deb` that installs as a binary. Maintenance is two lanes: **apt** (official + third-party repos) and **Flatpak**.

## Facts

- Root fs: `/dev/nvme0n1p2` (btrfs, label `debian`) · subvols `@ @home @log @snapshots`
- ESP: `/dev/nvme0n1p1` (vfat, **shared with Windows 11** — never reformat)
- Mount opts: `compress=zstd:3,noatime`
- Suite: `unstable` (Sid) · deb822 `.sources` format
- Bootloader: systemd-boot · Init: systemd

---

## 00 · Strategy — the two-lane binary system
*why Debian, and the shape of the result*

Everything installs prebuilt. You read nothing about compile flags; you read about **which repo a package comes from**. Two lanes carry all software:

1. **apt** — the Debian archive (official, huge, prebuilt) plus signed third-party vendor repos. This is the point of the move: vendors ship `.deb` + apt repos, and Debian resolves them natively.
2. **Flatpak** — sandboxed apps you'd rather keep off apt entirely (Zen, proprietary GUIs).

> [!warning] Sid discipline, not Sid fear
> Unstable's real risk is *breakage during library transitions*, not security (fixes land in unstable first). Never blind-upgrade: snapshot, then skim `apt-listbugs` output, then proceed. With snapper + that habit, Sid is a stable daily driver.

> [!note] Verify names, don't guess
> Confirm package names with `apt-cache search <term>` / `apt show <pkg>` before installing.

## 01 · Live environment & tooling
*boot any live Linux that has debootstrap; drive over SSH*

Boot a Debian live/netinst (or any live distro), get network, and install the bootstrap tools into the live environment.

*live env — as root*
```bash
# network first (wifi example)
nmtui   # or: iwctl station wlan0 connect "SSID"
ping -c2 deb.debian.org

apt update && apt install -y debootstrap arch-install-scripts btrfs-progs

# optional: let yourself in remotely, then work in tmux
passwd; systemctl start ssh; ip -brief addr
```

## 02 · Disk & btrfs subvolumes
*shared ESP with Windows*

> [!danger] Never reformat the shared ESP
> `/dev/nvme0n1p1` holds the Windows Boot Manager. Only create/format the Linux root partition. On a reinstall where `@home` is already intact on disk, don't `mkfs` at all — reuse the existing subvolumes and only recreate `@` and `@log`.

*create fs + flat subvolume layout*
```bash
# FRESH ONLY: mkfs.btrfs -L debian /dev/nvme0n1p2
mount /dev/nvme0n1p2 /mnt/debian
# FRESH ONLY:
btrfs subvolume create /mnt/debian/@
btrfs subvolume create /mnt/debian/@home
btrfs subvolume create /mnt/debian/@log
btrfs subvolume create /mnt/debian/@snapshots
umount /mnt/debian

mount -o subvol=@,compress=zstd:3,noatime /dev/nvme0n1p2 /mnt/debian
mkdir -p /mnt/debian/{efi,home,var/log,.snapshots}
mount -o subvol=@home,compress=zstd:3,noatime      /dev/nvme0n1p2 /mnt/debian/home
mount -o subvol=@log,compress=zstd:3,noatime       /dev/nvme0n1p2 /mnt/debian/var/log
mount -o subvol=@snapshots,compress=zstd:3,noatime /dev/nvme0n1p2 /mnt/debian/.snapshots
mount /dev/nvme0n1p1 /mnt/debian/efi
```

> [!warning] ESP size — kernels live here with systemd-boot
> systemd-boot reads only the ESP (vfat), so the kernel + initramfs are copied there. A stock Windows 100 MB ESP is too small for that. If yours is small, either enlarge it, or keep only 1–2 kernels (Phase 06 sets a small initramfs to help). Confirm free space with `df -h /mnt/debian/efi` before proceeding.

## 03 · Bootstrap the base system
*debootstrap Sid + deb822 apt sources*

```bash
debootstrap sid /mnt/debian http://deb.debian.org/debian
```

> [!note] If Sid is mid-transition and debootstrap errors
> Bootstrap `testing` instead, then switch the suite to `unstable` (below) and `apt full-upgrade` inside the chroot. Same endpoint, calmer bootstrap.

*write /mnt/debian/etc/apt/sources.list.d/debian.sources*
```bash
cat > /mnt/debian/etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: unstable
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
```

## 04 · Enter the chroot
```bash
cp --dereference /etc/resolv.conf /mnt/debian/etc/
mount --types proc /proc /mnt/debian/proc
mount --rbind /sys /mnt/debian/sys && mount --make-rslave /mnt/debian/sys
mount --rbind /dev /mnt/debian/dev && mount --make-rslave /mnt/debian/dev
mount --bind /run /mnt/debian/run
chroot /mnt/debian /bin/bash

export PS1="(chroot) $PS1"
apt update
apt install -y locales console-setup btrfs-progs
```

## 05 · fstab · time · locale · machine-id
*machine-id must exist before the kernel phase*

> [!warning] Unquoted heredoc for fstab
> Use `<<EOF` (not `<<'EOF'`) so the `$(blkid …)` substitutions expand to real UUIDs.

```bash
ROOT=$(blkid -s UUID -o value /dev/nvme0n1p2)
EFI=$(blkid -s UUID -o value /dev/nvme0n1p1)
cat > /etc/fstab <<EOF
UUID=$ROOT  /           btrfs  subvol=@,compress=zstd:3,noatime          0 0
UUID=$ROOT  /home       btrfs  subvol=@home,compress=zstd:3,noatime      0 0
UUID=$ROOT  /var/log    btrfs  subvol=@log,compress=zstd:3,noatime       0 0
UUID=$ROOT  /.snapshots btrfs  subvol=@snapshots,compress=zstd:3,noatime 0 0
UUID=$EFI   /efi        vfat   defaults,noatime                          0 2
EOF
```

```bash
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
sed -i 's/^# *\(en_US.UTF-8\|de_DE.UTF-8\)/\1/' /etc/locale.gen
locale-gen && update-locale LANG=en_US.UTF-8
echo "workforce" > /etc/hostname

systemd-machine-id-setup        # BEFORE the kernel — entries are keyed on machine-id
```

## 06 · Kernel & systemd-boot
*the cmdline is mandatory here; installing systemd-boot wires everything*

> [!warning] cmdline is required — initramfs-tools has no DPS
> Debian's `initramfs-tools` cannot discover the root filesystem at boot, so `/etc/kernel/cmdline` **must** carry `root=UUID=…` and the btrfs `rootflags=subvol=@`. Miss this and you boot to an emergency shell.

```bash
ROOT=$(blkid -s UUID -o value /dev/nvme0n1p2)
echo "root=UUID=$ROOT rootflags=subvol=@ rw quiet" > /etc/kernel/cmdline

# shrink the initramfs (helps a small shared ESP): dep = only needed modules
sed -i 's/^MODULES=.*/MODULES=dep/' /etc/initramfs-tools/initramfs.conf

apt install -y linux-image-amd64 firmware-linux intel-microcode
```

> [!success] One package installs the whole bootloader
> Installing `systemd-boot` runs `bootctl install`, registers it in the UEFI boot order, and creates loader entries for the kernel already present — no manual `bootctl`, no hand-written entries. Future kernel upgrades regenerate entries automatically via the kernel hook.

```bash
apt install -y systemd-boot efibootmgr
bootctl status          # confirm systemd-boot is installed on the ESP
bootctl list            # a Debian entry with your kernel must appear
```

## 07 · Users · sudo · network · base tools
```bash
passwd                              # root
apt install -y sudo network-manager zstd git curl ca-certificates

useradd -m -G sudo,audio,video,plugdev -s /bin/bash naeem
passwd naeem

systemctl enable NetworkManager ssh systemd-timesyncd
```

## 08 · Boot order & first reboot
> [!warning] Windows steals the shared ESP boot order
> Force the Linux Boot Manager first with **your** entry numbers.

```bash
efibootmgr                      # find the 'Linux Boot Manager' number
efibootmgr -o 0001,0000         # Linux first, Windows second

exit
umount -R /mnt/debian
reboot
```

*Log in, start `tmux`, SSH from your desk, and run the rest remotely. systemd-boot auto-detects Windows Boot Manager on the shared ESP, so the dual-boot menu is already correct.*

---

## 09 · Minimal Plasma
*a full Wayland desktop, no app-suite — the `--no-install-recommends` is the minimalism lever*

> [!success] qtwebengine is a non-event
> Whatever pulls `qtwebengine` here gets a prebuilt `.deb`. There is nothing to configure, verify, or keep binary — it simply is.

```bash
sudo apt update && sudo apt full-upgrade -y

# minimal metapackage + Wayland session + SDDM, WITHOUT the recommended extras
sudo apt install --no-install-recommends -y \
  plasma-desktop plasma-workspace-wayland sddm

sudo systemctl enable sddm
```

> [!note] The three metapackage tiers
> `plasma-desktop` = minimal (what you want). `kde-standard` = fuller day-to-day set (Kate, Okular, KMail, Gwenview…). `kde-full` = the lot. `--no-install-recommends` suppresses the optional Recommends that apt would otherwise pull.

## 10 · Common add-ons
*KDE Connect, wallet, Dolphin + remote folders — all plain `.deb`*

```bash
sudo apt install -y \
  kdeconnect kwalletmanager \
  dolphin kio-extras          # kio-extras brings sftp:// smb:// fish:// workers
```

> [!note] SMB included
> `kio-extras` ships the SMB/SFTP workers already — no per-flag rebuild needed. KWallet integration comes with the Plasma session. If you run a firewall, KDE Connect still needs TCP+UDP `1714–1764`.

## 11 · Desktop essentials
*audio, power, portals, fonts*

```bash
# PipeWire is the Sid default; ensure the stack + portal + power daemon:
sudo apt install -y \
  pipewire-audio wireplumber \
  power-profiles-daemon \
  xdg-desktop-portal-kde \
  fonts-jetbrains-mono fonts-noto fonts-noto-color-emoji

# Arabic + Nerd symbols: verify names in the archive first
apt-cache search amiri            # e.g. fonts-hosny-amiri
apt-cache search nerd             # symbols nerd font may need manual install
fc-cache -fr
```

---

## 12 · Third-party `.deb` lane
*the reason for the whole migration — signed vendor repos*

The modern, correct pattern: drop the vendor's key in `/etc/apt/keyrings/`, add a deb822 `.sources` file with `Signed-By`, then `apt install`. Generic template:

```bash
sudo install -m0755 -d /etc/apt/keyrings
curl -fsSL https://vendor.example/key.gpg \
  | sudo tee /etc/apt/keyrings/vendor.gpg >/dev/null

sudo tee /etc/apt/sources.list.d/vendor.sources >/dev/null <<'EOF'
Types: deb
URIs: https://vendor.example/apt
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/vendor.gpg
EOF

sudo apt update && sudo apt install -y <vendor-package>
```

> [!warning] Pin third-party repos to their own suite
> Vendor repos target `stable`, not `sid`. They usually coexist fine, but if a vendor package fights Sid's libraries, add an apt pin (`/etc/apt/preferences.d/`) to keep it from pulling half of stable. Keep the vendor-repo list short and audited.

> [!note] Real examples
> Docker, VS Code, Google Chrome, Mullvad, and many others publish exactly this: a keyring + apt repo. Standalone `.deb` files (no repo) install with `sudo apt install ./file.deb` — apt resolves their deps.

## 13 · Flatpak lane
*sandboxed apps, off apt entirely*

```bash
sudo apt install -y flatpak
flatpak remote-add --if-not-exists --user \
  flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install --user flathub app.zen_browser.zen
```

> [!success] Portal already in place
> `xdg-desktop-portal-kde` from Phase 11 gives Flatpak apps native file dialogs and screen-share under Plasma. `--user` keeps installs in `@home`, so they survive a root rollback and ride your normal backup.

## 14 · Dotfiles & tooling
```bash
sudo apt install -y zsh stow ghostty nemo mise
# (verify: some tools may come from a vendor repo added in Phase 12)

git clone <dotfiles-remote> ~/dotfiles
cd ~/dotfiles && git switch machine/workforce
stow zsh ghostty git mise ...
chsh -s /bin/zsh naeem
mise install
```

---

## 15 · Snapper & two-lane maintenance
*rollback net + the weekly pass across apt and Flatpak*

> [!warning] Unmount /.snapshots before create-config
> snapper wants to make its own `.snapshots` subvol. Unmount yours, let it create the config, delete its fresh one, remount yours.

```bash
sudo apt install -y snapper
sudo umount /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mount /.snapshots
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
```

*Optional — auto-snapshot before every apt transaction:*
```bash
sudo tee /etc/apt/apt.conf.d/80snapper >/dev/null <<'EOF'
DPkg::Pre-Invoke { "snapper -c root create -d apt-pre >/dev/null 2>&1 || true"; };
EOF
```

**Weekly, both lanes:**
```bash
sudo snapper -c root create -d "pre-update $(date +%F)"
sudo apt update
apt list --upgradable                 # skim before committing
sudo apt full-upgrade                 # 'full' handles Sid's transitions
sudo apt autoremove --purge
flatpak update --user && flatpak uninstall --user --unused
```

> [!danger] Rollback is manual with systemd-boot
> This is the tradeoff of choosing systemd-boot over GRUB+grub-btrfs: there are no auto-generated "boot into snapshot" menu entries. Recover from a live USB — mount the btrfs top level, `mv @ @broken`, `btrfs subvolume snapshot /.snapshots/<n>/snapshot @`, reboot. `@home`, your `--user` Flatpaks, and `@snapshots` sit outside `@` and survive the swap.

---

## Restore checklist
- [ ] btrfs mounted, `@home` preserved (migration) or created (fresh)
- [ ] ESP has room for kernel+initramfs · `MODULES=dep` set
- [ ] deb822 `unstable` sources · machine-id before kernel
- [ ] `/etc/kernel/cmdline` has `root=UUID` + `rootflags=subvol=@`
- [ ] `systemd-boot` installed · `bootctl list` shows the kernel
- [ ] efibootmgr order = Linux first
- [ ] `plasma-desktop` only, `--no-install-recommends` · add-ons · portals · fonts
- [ ] third-party repos added (keyring + `Signed-By`, pinned) · Flatpak apps restored
- [ ] dotfiles stowed · snapper + pre-apt hook + weekly timer live

---
*Debian Sid · Plasma · systemd-boot · btrfs/snapper · Rev. 1*
