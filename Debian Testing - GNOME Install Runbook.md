---
title: "Debian Testing: GNOME Install Runbook"
aliases: ["Debian Testing Runbook", "Forky Runbook", "T490 Debian Rev 3"]
tags: [debian, testing, forky, gnome, niri, systemd-boot, btrfs, runbook, thinkpad-t490]
machine: "ThinkPad T490 (20N2004AGE)"
arch: "amd64"
init: "systemd + systemd-boot"
filesystem: "btrfs + snapper"
desktop: "GNOME (Wayland), niri + Noctalia later"
method: "debootstrap"
supersedes: "Debian Sid — Plasma Install Runbook.md"
rev: "3"
---

# Debian Testing + GNOME: a binary-native daily driver

**Debian testing**, tracked through the rolling `testing` alias: prebuilt everything, a btrfs + snapper + systemd-boot spine, and native access to the third-party `.deb` ecosystem. Installed by hand with `debootstrap` for full control over the disk layout and bootloader.

> [!info] Legend
> `[!warning]` = a gotcha to get right · `[!success]` = a binary-native win · `[!danger]` = can lock you out / data loss · `[!note]` = info.

> [!success] Binary-native by default
> No stage3, no profiles, no USE flags, no build matching, no overlays. `qtwebengine` is just a `.deb` that installs as a binary. Maintenance is two lanes: **apt** (official + third-party repos) and **Flatpak**.

## What changed from Rev 1

Rev 1 targeted Sid on a disk shared with Windows 11. Two things changed, and the second one touches more of this document than the first.

1. **Suite: unstable becomes testing.** Affects the bootstrap, the sources file, and the upgrade discipline. Nothing else.
2. **The disk is blank. No Windows, no existing partition table.** Every "never reformat the shared ESP" constraint is gone, the ESP can finally be sized properly, the boot-order fight with Windows Boot Manager disappears, and a partitioning step that Rev 1 never needed is now Step 02.
3. **Desktop: Plasma becomes GNOME** (Rev 3), with niri + Noctalia as a later migration in Step 17 rather than the starting point.

Sections are numbered as **Steps** rather than Phases. The btrfs layout, chroot, machine-id ordering, kernel cmdline, systemd-boot, the two software lanes, and snapper are all unchanged from Rev 1, because none of them depend on the suite, on Windows, or on the desktop.

## Facts

- Disk: `/dev/nvme0n1`, wiped, GPT created fresh in Step 02
- ESP: `/dev/nvme0n1p1` (vfat, 1 GiB, Linux only)
- Root fs: `/dev/nvme0n1p2` (btrfs, label `debian`) · subvols `@ @home @log @snapshots`
- Mount opts: `compress=zstd:3,noatime`
- Suite: `testing` (rolling alias, currently forky) · deb822 `.sources` format
- Bootloader: systemd-boot · Init: systemd

---

## 00 · Strategy · the two-lane binary system
*why Debian, and the shape of the result*

Everything installs prebuilt. You read nothing about compile flags; you read about **which repo a package comes from**. Two lanes carry all software:

1. **apt**: the Debian archive (official, huge, prebuilt) plus signed third-party vendor repos. This is the point of the move: vendors ship `.deb` + apt repos, and Debian resolves them natively.
2. **Flatpak**: sandboxed apps you'd rather keep off apt entirely (Zen, proprietary GUIs).

> [!warning] Testing discipline, not testing complacency
> Testing changes more often than stable and less violently than unstable. What you gain over Sid is the migration filter: a package sits in unstable 2 to 10 days and must be free of new release-critical bugs before it reaches you, which catches the worst library-transition breakage. What you give up is security latency, because every fix lands in unstable first. The habit is the same either way: snapshot, skim `apt-listbugs`, then upgrade.

> [!warning] No security archive exists for testing
> There is no `testing-security` suite to add to your sources, and this is not an oversight in the runbook. Security fixes reach testing only by migrating out of unstable on the normal 2 to 10 day schedule, and can be held longer by an in-flight transition. Debian's security FAQ is explicit that anything security-critical belongs on stable. On a laptop with snapshots and a rollback path this is a fair trade. Do not extend the same reasoning to a server.

> [!note] Verify names, don't guess
> Confirm package names with `apt-cache search <term>` / `apt show <pkg>` before installing.

## 01 · Live environment & tooling
*boot any live Linux that has debootstrap; drive over SSH*

Boot a Debian live/netinst (or any live distro), get network, and install the bootstrap tools into the live environment.

*live env, as root*
```bash
# network first (wifi example)
nmtui   # or: iwctl station wlan0 connect "SSID"
ping -c2 deb.debian.org

apt update && apt install -y debootstrap arch-install-scripts btrfs-progs gdisk dosfstools parted

# optional: let yourself in remotely, then work in tmux
passwd; systemctl start ssh; ip -brief addr
```

> [!note] `gdisk`, `dosfstools` and `parted` are new in Rev 2
> Rev 1 never partitioned anything, so it never needed `sgdisk`, `mkfs.vfat`, or `partprobe`. Step 02 uses all three.

## 02 · Partition the blank disk
*GPT, a 1 GiB ESP, and the rest for root*

> [!danger] This destroys everything on the target device
> Confirm the device name before every command below. On this machine root is `nvme0n1`, but a USB stick can shift enumeration. `lsblk` first, every time, and match the size to the internal disk.

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
```

*create a fresh GPT with two partitions*
```bash
wipefs -a /dev/nvme0n1          # clear stale filesystem signatures
sgdisk --zap-all /dev/nvme0n1   # drop any existing GPT and MBR

sgdisk -n 1:0:+1G -t 1:ef00 -c 1:"EFI System" /dev/nvme0n1
sgdisk -n 2:0:0   -t 2:8300 -c 2:"Linux root" /dev/nvme0n1

partprobe /dev/nvme0n1
lsblk /dev/nvme0n1              # p1 = 1G, p2 = the rest
```

*format both*
```bash
mkfs.vfat -F 32 -n ESP /dev/nvme0n1p1
mkfs.btrfs -L debian /dev/nvme0n1p2
```

> [!success] The ESP is yours alone now
> Rev 1 inherited a stock Windows 100 MB ESP that had to be shared and could not be reformatted, which is why it rationed kernels and shrank the initramfs to fit. With 1 GiB and no other OS on the disk, kernel space stops being a constraint. `MODULES=dep` in Step 07 stays because a smaller initramfs is still nicer, but it is now a preference and not a workaround.

## 03 · btrfs subvolumes & mount layout

*flat subvolume layout*
```bash
mount /dev/nvme0n1p2 /mnt/debian
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

> [!note] Why `@home` is a subvolume on a fresh install
> Nothing to preserve this time, but keeping `@home` separate is what makes the Step 16 rollback safe: swapping a broken `@` for a snapshot leaves home, your `--user` Flatpaks, and the snapshots themselves untouched.

## 04 · Bootstrap the base system
*debootstrap testing + deb822 apt sources*

```bash
debootstrap testing /mnt/debian http://deb.debian.org/debian
```

> [!success] The alias sidesteps a bootstrap problem
> `debootstrap` resolves a suite name against a script in `/usr/share/debootstrap/scripts`. A codename like `forky` may be missing on an older live image; `testing` is always present. Since this build tracks the alias anyway, the two choices agree. Check with `ls /usr/share/debootstrap/scripts | grep testing` if it errors.

*write /mnt/debian/etc/apt/sources.list.d/debian.sources*
```bash
cat > /mnt/debian/etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: testing
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
```

> [!warning] `testing` is an alias, and it keeps rolling forever
> This is the deliberate choice for this machine. `Suites: testing` follows whatever Debian currently calls testing, which is forky (Debian 14) today. On the day forky is released as stable, the alias moves to Debian 15's freshly opened testing and this laptop follows it into the new cycle rather than settling into stable. Writing `Suites: forky` instead would have tracked that one release through into stable and then oldstable. Expect the sharpest churn and the worst security lag in the months right after each stable release, and snapshot harder in that window.

## 05 · Enter the chroot
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

## 06 · fstab · time · locale · machine-id
*machine-id must exist before the kernel step*

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

systemd-machine-id-setup        # BEFORE the kernel: entries are keyed on machine-id
```

## 07 · Kernel & systemd-boot
*the cmdline is mandatory here; installing systemd-boot wires everything*

> [!warning] cmdline is required, initramfs-tools has no DPS
> Debian's `initramfs-tools` cannot discover the root filesystem at boot, so `/etc/kernel/cmdline` **must** carry `root=UUID=…` and the btrfs `rootflags=subvol=@`. Miss this and you boot to an emergency shell. This is unchanged from Rev 1 and has nothing to do with the suite.

> [!warning] Order matters here, and Rev 1 got it wrong
> `/etc/initramfs-tools/initramfs.conf` ships in `initramfs-tools-core`, which only arrives as a dependency of `linux-image-amd64`. Editing it before installing the kernel fails with `sed: can't read … No such file or directory`. Install `initramfs-tools` first so the config exists, then edit, then install the kernel, which builds the initramfs small the first time. A fresh debootstrap chroot may also lack `/etc/kernel`, so create it before the redirect or the cmdline silently never gets written.

```bash
ROOT=$(blkid -s UUID -o value /dev/nvme0n1p2)
mkdir -p /etc/kernel
echo "root=UUID=$ROOT rootflags=subvol=@ rw quiet" > /etc/kernel/cmdline
cat /etc/kernel/cmdline     # must show a real UUID, not an empty root=UUID=

# smaller initramfs: dep = only needed modules. Optional now, see Step 02.
apt install -y initramfs-tools
sed -i 's/^MODULES=.*/MODULES=dep/' /etc/initramfs-tools/initramfs.conf
grep ^MODULES= /etc/initramfs-tools/initramfs.conf   # must print MODULES=dep

apt install -y linux-image-amd64 firmware-linux intel-microcode
```

> [!note] If you already installed the kernel first
> No harm done. Run the `sed` now, then `update-initramfs -u -k all` to rebuild the existing initramfs with the smaller module set.

> [!success] One package installs the whole bootloader
> Installing `systemd-boot` runs `bootctl install`, registers it in the UEFI boot order, and creates loader entries for the kernel already present. No manual `bootctl`, no hand-written entries. Future kernel upgrades regenerate entries automatically via the kernel hook.

```bash
apt install -y systemd-boot efibootmgr
bootctl status          # confirm systemd-boot is installed on the ESP
bootctl list            # a Debian entry with your kernel must appear
```

## 08 · Users · sudo · network · base tools
*install the packages, then enable their units*

> [!warning] Install the units before enabling them, and Rev 1 got this wrong too
> `systemctl enable ssh` fails with `Unit ssh.service does not exist` unless `openssh-server` is installed, and `systemd-timesyncd` is its own package in forky rather than part of `systemd`, so it fails the same way one argument later. Both are missing from a fresh debootstrap. The unit name `ssh` is correct: `openssh-server` ships `ssh.service`, not `sshd.service`.

> [!danger] No sshd here means no remote install
> Step 09 has you reboot and finish the desktop over SSH. The `ssh` you started back in Step 01 belongs to the live environment, not to the system being built. Skip `openssh-server` and you reboot into a machine you cannot log into remotely.

```bash
passwd                              # root
apt install -y sudo network-manager openssh-server systemd-timesyncd \
               zstd git curl ca-certificates

useradd -m -G sudo,audio,video,plugdev -s /bin/bash naeem
passwd naeem

systemctl enable NetworkManager ssh systemd-timesyncd
systemctl is-enabled NetworkManager ssh systemd-timesyncd   # expect three 'enabled' lines
```

## 09 · First reboot
```bash
efibootmgr              # 'Linux Boot Manager' should be present and first
exit
umount -R /mnt/debian
reboot
```

> [!note] No boot order to fight over
> Rev 1 needed `efibootmgr -o` here to stop the Windows Boot Manager taking priority on the shared ESP. With a single OS on the disk, `bootctl install` from Step 07 has already put Linux Boot Manager first, so `efibootmgr` is now a verification step rather than a fix. There will also be no Windows entry in the systemd-boot menu, which is correct.

*Log in, start `tmux`, SSH from your desk, and run the rest remotely.*

---

## 10 · Minimal GNOME
*a full Wayland desktop from one curated metapackage*

> [!success] qtwebengine is a non-event
> Whatever pulls `qtwebengine` here gets a prebuilt `.deb`. There is nothing to configure, verify, or keep binary. It simply is.

```bash
sudo apt update && sudo apt full-upgrade -y

sudo apt install -y gnome-core
sudo systemctl enable gdm3
```

> [!warning] Do not reach for `--no-install-recommends` here
> That flag was the minimalism lever for `plasma-desktop`, and carrying the habit over to GNOME is the mistake this callout exists to prevent. `gnome-core` is already the curated minimum, and GNOME leans on Recommends for portal, keyring, and session integration, so stripping them leaves a desktop missing pieces you then debug one at a time. If you want tighter than `gnome-core`, drop to `gnome-shell` and add components deliberately.

> [!note] The three metapackage tiers
> `gnome-shell` = the shell alone, you assemble the session yourself. `gnome-core` = curated minimal desktop, depends on `gdm3` and `gnome-shell` (both >= 48) and brings nautilus (what you want). `gnome` = the full environment with extra apps and games.

`gnome-core` already depends on `gdm3`, so the `systemctl enable gdm3` above is usually a no-op. It is cheap to run and cheaper than a black screen on first boot.

## 11 · Common add-ons
*keyring, file manager, phone integration*

```bash
sudo apt install -y gnome-keyring

# nautilus arrives with gnome-core; nemo is what the dotfiles and niri binds expect
sudo apt install -y nemo
```

> [!note] Verify the KDE Connect equivalent before installing
> Under GNOME the integration is a shell extension rather than the Plasma applet. Search the archive first, per Step 00: `apt-cache search gsconnect` and `apt-cache search kdeconnect`. The `kdeconnect` package itself still works outside Plasma if you prefer it. Whichever you pick, a firewall still needs TCP+UDP `1714-1764`.

> [!note] Why nemo and not just nautilus
> The dotfiles and the niri keybinds on the other machine both call `nemo`, so installing it now keeps Step 15 and Step 17 consistent. Leaving nautilus in place costs nothing.

## 12 · Desktop essentials
*audio, power, portals, fonts*

```bash
# PipeWire is the default; ensure the stack + portal + power daemon:
sudo apt install -y \
  pipewire-audio wireplumber \
  power-profiles-daemon \
  xdg-desktop-portal-gnome \
  fonts-jetbrains-mono fonts-noto fonts-noto-color-emoji

# Arabic + Nerd symbols: verify names in the archive first
apt-cache search amiri            # e.g. fonts-hosny-amiri
apt-cache search nerd             # symbols nerd font may need manual install
fc-cache -fr
```

---

## 13 · Third-party `.deb` lane
*the reason for the whole migration: signed vendor repos*

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

> [!success] This lane gets easier on testing
> Vendor repos target `stable`, and testing sits far closer to trixie than Sid does, so the library mismatches Rev 1 warned about are much less likely. Keep the pin habit anyway: if a vendor package starts dragging in half of stable, add an apt pin in `/etc/apt/preferences.d/`. Keep the vendor-repo list short and audited.

> [!note] Real examples
> Docker, VS Code, Google Chrome, Mullvad, and many others publish exactly this: a keyring + apt repo. Standalone `.deb` files (no repo) install with `sudo apt install ./file.deb` and apt resolves their deps.

## 14 · Flatpak lane
*sandboxed apps, off apt entirely*

```bash
sudo apt install -y flatpak
flatpak remote-add --if-not-exists --user \
  flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install --user flathub app.zen_browser.zen
```

> [!success] Portal already in place, and it survives the niri migration
> `xdg-desktop-portal-gnome` from Step 12 gives Flatpak apps native file dialogs and screen-share under GNOME. It is also the exact portal the niri setup on the other machine restarts at startup for screencasting, so Step 17 inherits it rather than replacing it. `--user` keeps installs in `@home`, so they survive a root rollback and ride your normal backup.

## 15 · Dotfiles & tooling
> [!warning] `ghostty` and `mise` are not in the Debian archive
> Checked on packages.debian.org across every suite: no `ghostty` package at all, and nothing matching `mise` as the version manager. `apt install ghostty mise` fails with "Unable to locate package" twice. Both come from upstream, so route them through the Step 13 vendor pattern (keyring, deb822 `.sources`, `Signed-By`, pinned) or a source build, and verify who publishes the repo before trusting it. `zsh`, `stow`, and `nemo` are all in the archive.

*apt lane*
```bash
sudo apt install -y zsh stow          # nemo already installed in Step 11
chsh -s /bin/zsh naeem
```

*dotfiles*
```bash
git clone <dotfiles-remote> ~/dotfiles
cd ~/dotfiles && git switch machine/workforce
stow zsh fish ghostty nvim btop starship tmux k9s noctalia
```

> [!note] Stow only what the branch actually carries
> The packages on `machine/workforce` are `btop fish ghostty hypr k9s noctalia nvim starship tmux zsh`. There is no `git` or `mise` package in the repo, and `hypr` is stale for this machine now that the target is GNOME then niri. Stow `ghostty` even before the terminal is installed; the config simply waits for it.

> [!note] The niri config lives on the other branch
> `machine/workforce` has no `niri` package. When you reach Step 17 the compositor config has to come across from `machine/ri-t-0931`, by cherry-pick rather than merge, since the two branches carry deliberately different package sets.

> [!note] `AGENTS.md` on this branch still says "Base OS: Debian sid"
> It also describes Hyprland as the compositor. Update both once the machine is up, or the next session's context starts from a false premise.

> [!note] `AGENTS.md` on this branch still says "Base OS: Debian sid"
> Update it once the machine is up, or the next session's context starts from a false premise.

---

## 16 · Snapper & two-lane maintenance
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

*Optional, auto-snapshot before every apt transaction:*
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
sudo apt full-upgrade                 # 'full' handles testing's transitions too
sudo apt autoremove --purge
flatpak update --user && flatpak uninstall --user --unused
```

> [!warning] The release-day spike
> Because this machine tracks the `testing` alias, the weeks after any Debian stable release are the roughest patch in the cycle: the alias has just re-pointed at a newly opened suite, churn is at its highest, and security fixes lag most. Read `apt list --upgradable` properly in that window rather than skimming, and consider holding off entirely for a few weeks.

> [!danger] Rollback is manual with systemd-boot
> This is the tradeoff of choosing systemd-boot over GRUB+grub-btrfs: there are no auto-generated "boot into snapshot" menu entries. Recover from a live USB: mount the btrfs top level, `mv @ @broken`, `btrfs subvolume snapshot /.snapshots/<n>/snapshot @`, reboot. `@home`, your `--user` Flatpaks, and `@snapshots` sit outside `@` and survive the swap.

---

---

## 17 · Later · niri + Noctalia
*the eventual target, and the one place this machine leaves the two-lane premise*

Not part of the first install. Get GNOME stable, dotfiles stowed, and snapper working first, then come back. GNOME stays installed either way: it is a working fallback session at the gdm3 login screen while niri is still being tuned.

> [!danger] niri is not in the Debian archive
> Checked on packages.debian.org: forky ships `librust-niri-ipc-dev` and `niri-companion` (5.0.0), but there is **no `niri` package**. Quickshell, which Noctalia runs on, **is** packaged: `quickshell` 0.3.0-1 in forky, also available in trixie-backports.
> So the shell half of the target is apt-native and the compositor half is not. This is the single point where the machine departs from the two-lane premise in Step 00, and it is worth deciding deliberately rather than discovering mid-migration.

**Pick a lane for niri before starting, and write down which one you picked:**

1. **Build from source.** Rust and cargo, a third lane on top of apt and Flatpak, and a compositor you now maintain by hand across testing's library churn. Honest but ongoing work.
2. **A trusted third-party repo.** Treat it exactly like any vendor repo in Step 13: keyring in `/etc/apt/keyrings/`, deb822 `.sources` with `Signed-By`, pinned. Verify who publishes it before trusting it with your session.

Neither is verified in this runbook. Whichever you choose, capture the exact steps here afterwards so the next rebuild is not a research project.

**What is already settled:**

```bash
# The Noctalia runtime is a normal apt package
sudo apt install -y quickshell
```

> [!note] Noctalia's shell code is not in the dotfiles repo
> The `noctalia/` package carries settings, colorschemes, and plugins, not the shell itself. The shell comes from upstream separately and is launched with `qs -c noctalia-shell --no-duplicate`. Budget for that as its own step.

> [!note] Session entry
> The other machine launches niri from `~/.zprofile` via `start-niri.sh`, which execs `niri-session` so the ScreenCast D-Bus interface registers. With gdm3 already installed here you can instead drop a niri session file and pick it at the login screen, which keeps GNOME one menu entry away when something breaks. Decide once and keep the dotfiles consistent with it.

---

## Restore checklist
- [ ] correct device confirmed with `lsblk` before `sgdisk --zap-all`
- [ ] GPT created · 1 GiB ESP (`ef00`) · root partition (`8300`) · both formatted
- [ ] btrfs subvolumes created and mounted · `/mnt/debian/efi` mounted
- [ ] deb822 sources with `Suites: testing` · machine-id before kernel
- [ ] `/etc/kernel/cmdline` has `root=UUID` + `rootflags=subvol=@`
- [ ] `systemd-boot` installed · `bootctl list` shows the kernel
- [ ] `efibootmgr` shows Linux Boot Manager first
- [ ] `openssh-server` and `systemd-timesyncd` installed · all three units report `enabled` before rebooting
- [ ] `gnome-core` installed WITHOUT `--no-install-recommends` · gdm3 enabled · add-ons · portals · fonts
- [ ] third-party repos added (keyring + `Signed-By`, pinned) · Flatpak apps restored
- [ ] dotfiles stowed · snapper + pre-apt hook + weekly timer live
- [ ] `AGENTS.md` updated from "Debian sid" to "Debian testing", and from Hyprland to GNOME
- [ ] Step 17 deferred deliberately, not forgotten · niri lane chosen and written down

---
*Debian testing (rolling alias) · GNOME now, niri + Noctalia later · systemd-boot · btrfs/snapper · Rev. 3*
