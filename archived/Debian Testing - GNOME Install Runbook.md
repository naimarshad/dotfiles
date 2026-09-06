---
title: "Debian Testing: GNOME Install Runbook"
aliases: ["Debian Testing Runbook", "Forky Runbook", "T490 Debian Rev 4"]
tags: [debian, testing, forky, gnome, niri, systemd-boot, btrfs, runbook, thinkpad-t490]
machine: "ThinkPad T490 (20N2004AGE)"
arch: "amd64"
init: "systemd + systemd-boot"
filesystem: "btrfs + snapper"
desktop: "GNOME (Wayland) first boot, then niri (source build) + Noctalia (apt repo)"
display-manager: "gdm3 for the GNOME phase, then greetd + noctalia-greeter"
method: "debootstrap"
supersedes: "Debian Sid — Plasma Install Runbook.md"
rev: "4"
---

# Debian Testing + GNOME: a binary-native daily driver

**Debian testing**, tracked through the rolling `testing` alias: prebuilt everything, a btrfs + snapper + systemd-boot spine, and native access to the third-party `.deb` ecosystem. Installed by hand with `debootstrap` for full control over the disk layout and bootloader.

> [!info] Legend
> `[!warning]` = a gotcha to get right · `[!success]` = a binary-native win · `[!danger]` = can lock you out / data loss · `[!note]` = info.

> [!success] Binary-native by default
> Everything installs prebuilt. `qtwebengine` is just a `.deb`. Maintenance is two lanes: **apt** (official + third-party repos) and **Flatpak**, plus a small third lane for the two things that must be source-built (Step 17).

## Status

**Rev 4 is a record, not a plan.** The machine was built and every step below was reconciled against `~/.bash_history`, `~/.zsh_history`, and the running system. Steps are numbered as Steps.

Earlier revisions, for context: Rev 1 was Sid + Plasma on a disk shared with Windows 11; Rev 2 added partitioning once the disk was blank; Rev 3 switched the suite to testing and the desktop to GNOME with niri sketched as "decide later". Rev 4 turned that sketch into the verified procedure and made niri the daily driver.

## Facts

- Disk: `/dev/nvme0n1`, wiped, GPT created fresh in Step 02
- ESP: `/dev/nvme0n1p1` (vfat, 1 GiB, Linux only)
- Root fs: `/dev/nvme0n1p2` (btrfs, label `debian`) · subvols `@ @home @log @snapshots`
- Mount opts: `compress=zstd:3,noatime`
- Suite: `testing` (rolling alias, currently forky) · deb822 `.sources` format
- Bootloader: systemd-boot · Init: systemd
- WiFi: Intel, needs `firmware-iwlwifi` (see Step 07)
- Display manager: `gdm3` during the GNOME phase, `greetd` + `noctalia-greeter` after Step 17
- Compositor: `niri` built from source to `/usr/local/bin/niri` · shell: `noctalia` from `pkg.noctalia.dev`

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

> [!note] 1 GiB ESP, Linux only
> Kernel space is not a constraint here. `MODULES=dep` in Step 07 is kept as a preference for a smaller initramfs, not as a workaround.

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

> [!note] Why `@home` is separate
> It makes the Step 16 rollback safe: swapping a broken `@` for a snapshot leaves home and the snapshots untouched. System-wide Flatpaks live in `/var/lib/flatpak` on `@` and do roll back with it (Step 14).

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
> Debian's `initramfs-tools` cannot discover the root filesystem at boot, so `/etc/kernel/cmdline` **must** carry `root=UUID=…` and the btrfs `rootflags=subvol=@`. Miss this and you boot to an emergency shell.

> [!warning] Order matters: initramfs-tools, then edit, then kernel
> `/etc/initramfs-tools/initramfs.conf` ships in `initramfs-tools-core`, which only arrives as a dependency of `linux-image-amd64`. Editing it before installing the kernel fails with `sed: can't read … No such file or directory`. Install `initramfs-tools` first so the config exists, then edit, then install the kernel. A fresh debootstrap chroot may also lack `/etc/kernel`, so create it before the redirect or the cmdline silently never gets written.

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

> [!warning] Intel WiFi needs `firmware-iwlwifi` explicitly
> On this build the WiFi card came up dead after first boot. `firmware-linux` pulls the non-free firmware bundle but the iwlwifi blobs for this generation of Intel card were still missing. Identify the card and install the dedicated package:
> ```bash
> apt install -y pciutils
> lspci | grep -i network        # confirm it is an Intel Wireless card
> apt install -y firmware-iwlwifi
> ```
> Do this in the chroot if you can, so the machine has network on the very first boot rather than needing a wired fallback to fix it.

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

> [!warning] Install the units before enabling them
> `systemctl enable ssh` fails with `Unit ssh.service does not exist` unless `openssh-server` is installed, and `systemd-timesyncd` is its own package in forky rather than part of `systemd`, so it fails the same way one argument later. Both are missing from a fresh debootstrap. The unit name `ssh` is correct: `openssh-server` ships `ssh.service`, not `sshd.service`.

> [!danger] No sshd here means no remote install
> Step 09 has you reboot and finish the desktop over SSH. The `ssh` you started back in Step 01 belongs to the live environment, not to the system being built. Skip `openssh-server` and you reboot into a machine you cannot log into remotely.

```bash
passwd                              # root
apt install -y sudo network-manager openssh-server systemd-timesyncd \
               zstd git curl ca-certificates

useradd -m -c "Naeem Arshad" -G sudo,audio,video,plugdev -s /bin/bash naeem
passwd naeem

systemctl enable NetworkManager ssh systemd-timesyncd
systemctl is-enabled NetworkManager ssh systemd-timesyncd   # expect three 'enabled' lines
```

> [!note] `docker` and `libvirt` groups come later
> They do not exist yet: the groups are created by the `docker-ce` and `libvirt-daemon-system` packages in Steps 19 and 20. `usermod -aG docker naeem` and `usermod -aG libvirt naeem` run there, after the packages, followed by a re-login. The full group set on the finished machine is `sudo audio video plugdev docker libvirt`.

## 09 · First reboot
```bash
efibootmgr              # 'Linux Boot Manager' should be present and first
exit
umount -R /mnt/debian
reboot
```

> [!note] `efibootmgr` here is a check, not a fix
> Single OS on the disk, so `bootctl install` from Step 07 has already put Linux Boot Manager first. No Windows entry in the systemd-boot menu is correct.

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
> `gnome-core` is already the curated minimum, and GNOME leans on Recommends for portal, keyring, and session integration. Stripping them leaves a desktop missing pieces you then debug one at a time. If you want tighter, drop to `gnome-shell` and add components deliberately.

> [!note] The three metapackage tiers
> `gnome-shell` = the shell alone, you assemble the session yourself. `gnome-core` = curated minimal desktop, depends on `gdm3` and `gnome-shell` (both >= 48) and brings nautilus (what you want). `gnome` = the full environment with extra apps and games.

`gnome-core` already depends on `gdm3`, so the `systemctl enable gdm3` above is usually a no-op. It is cheap to run and cheaper than a black screen on first boot.

> [!note] gdm3 is temporary
> Step 17 installs `noctalia-greeter`, whose package enables `greetd` and points `display-manager.service` at it instead. That is the intended end state. gdm3 stays installed as a fallback: `sudo systemctl disable greetd && sudo systemctl enable gdm3` swaps back to it if the graphical greeter breaks. For the GNOME-only phase, gdm3 is correct and this step stands.

## 11 · Common add-ons
*keyring, file manager, phone integration*

```bash
sudo apt install -y gnome-keyring
```

> [!note] File manager is nautilus, not nemo
> `gnome-core` already brings nautilus, so nothing extra is needed here. The `niri` config inherited `Mod+E { spawn "nemo"; }` from the other machine branch, where nemo was the file manager; that bind silently did nothing here until it was repointed to `spawn "nautilus"`. If you ever install `nemo` instead, change the bind back and keep the two agreeing.

> [!note] KDE Connect equivalent
> Under GNOME the integration is a shell extension. Check `apt-cache search gsconnect` and `apt-cache search kdeconnect` before picking; `kdeconnect` works outside Plasma too. Either way the firewall needs TCP+UDP `1714-1764`. The niri autostart already spawns `kdeconnectd` and `kdeconnect-indicator`.

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

*Theming the niri session expects (see `environment.kdl` in the `niri` stow package):*
```bash
sudo apt install -y qt6ct bibata-cursor-theme
```

**adw-gtk3 is not in the Debian archive and is built from source.** It needs `dart-sass`, which is also not packaged (Debian ships only the deprecated `ruby-sass`), so take the self-contained dart-sass release rather than pulling in the whole Node toolchain for theme CSS:

```bash
sudo apt install -y meson ninja-build

# dart-sass: standalone build, bundles its own Dart runtime, no Node needed
curl -fsSLO https://github.com/sass/dart-sass/releases/download/1.104.0/dart-sass-1.104.0-linux-x64.tar.gz
tar -xzf dart-sass-1.104.0-linux-x64.tar.gz
sudo cp -r dart-sass /opt/dart-sass
sudo ln -sf /opt/dart-sass/sass /usr/local/bin/sass
rm -rf dart-sass dart-sass-1.104.0-linux-x64.tar.gz
sass --version                    # expect 1.104.0

# adw-gtk3 itself, installed per-user into ~/.local/share/themes
git clone --depth=1 https://github.com/lassekongo83/adw-gtk3.git ~/adw-gtk3
cd ~/adw-gtk3
meson setup -Dprefix="$HOME/.local" build
ninja -C build install
ls ~/.local/share/themes         # expect adw-gtk3 and adw-gtk3-dark
```

Update later with `cd ~/adw-gtk3 && git pull && ninja -C build install`. A prebuilt tarball exists on the releases page if you would rather not build, but it pins you to a release and the source path is a two-command update.

> [!warning] Installing the theme is not enough: gsettings must point at it too
> `environment.kdl` exports `GTK_THEME`, `QT_QPA_PLATFORMTHEME`, and `XCURSOR_THEME` to every niri child, but the cursor theme and anything reading gsettings directly ignore those. On this build both keys still read `'Adwaita'` after the themes were installed, so nothing had visibly changed. Set them:
> ```bash
> gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
> gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
> gsettings set org.gnome.desktop.interface cursor-size 24
> gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
> ```
> These are per-user dconf state, not dotfiles, so they do not come back with `stow` and have to be re-run on a rebuild.

> [!warning] `environment.kdl` exports these names whether or not they exist
> niri sets `GTK_THEME=adw-gtk3`, `QT_QPA_PLATFORMTHEME=qt6ct`, and `XCURSOR_THEME=Bibata-Modern-Classic` for every child process even when none of them are installed, with no warning: apps silently fall back to Adwaita. All three were missing on this build until installed here. Verify with `ls /usr/share/icons ~/.local/share/themes` and `command -v qt6ct` rather than assuming the config is doing anything.

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

> [!note] Vendor repos target `stable`, and testing is close to it
> Library mismatches are unlikely but keep the pin habit: if a vendor package starts dragging in half of stable, add an apt pin in `/etc/apt/preferences.d/`. Keep the vendor-repo list short and audited.

> [!note] Real examples
> Docker, VS Code, Google Chrome, Mullvad, and many others publish exactly this: a keyring + apt repo. Standalone `.deb` files (no repo) install with `sudo apt install ./file.deb` and apt resolves their deps.

## 14 · Flatpak lane
*sandboxed apps, off apt entirely*

```bash
sudo apt install -y flatpak
sudo flatpak remote-add --if-not-exists \
  flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install flathub app.zen_browser.zen
```

> [!note] System-wide, not `--user`
> This build installed Flatpak apps system-wide (`flatpak remotes` shows `flathub system`, Zen installed as `system`). That is the canonical choice for this machine now. The tradeoff: a root `@` rollback (Step 16) does not touch `/var/lib/flatpak`, so a system Flatpak installed after the snapshot survives the rollback as an orphan, and one removed after the snapshot stays gone. `--user` installs live in `@home` and rollback-follow `@home` instead. If that matters more to you than shared installs, add `--user` back to both commands.

> [!success] Portal already in place, and it survives the niri migration
> `xdg-desktop-portal-gnome` from Step 12 gives Flatpak apps native file dialogs and screen-share under GNOME. It is also the exact portal the niri autostart restarts at startup for screencasting (see Step 17's `autostart.kdl`), so Step 17 inherits it rather than replacing it.

## 15 · Dotfiles & tooling
*apt lane*
```bash
sudo apt install -y zsh stow tmux     # nemo already installed in Step 11
sudo apt install -y neovim            # plain binary; the LazyVim config comes from the nvim stow package
chsh -s /bin/zsh naeem
```

> [!warning] `ghostty` and `mise` are not in the Debian archive
> Confirmed on packages.debian.org: no `ghostty` package in any suite, and nothing matching `mise` the version manager. What this build actually did:
> ```bash
> # ghostty: the community ghostty-ubuntu installer. It downloads a prebuilt
> # .deb and runs dpkg -i. No apt repo is left behind (apt-cache policy ghostty
> # shows only /var/lib/dpkg/status), so there is no auto-update: re-run the
> # script to upgrade. Installed 1.3.1-0~ppa2.
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
>
> # mise: upstream one-liner, lands at ~/.local/bin/mise and is activated in
> # ~/.zshrc via `eval "$(mise activate zsh)"` (see Step 18).
> curl https://mise.run | sh
> ```
> Both scripts are `curl | sh` from upstream. Read them once before trusting them.

*dotfiles*
```bash
git clone git@github.com:naimarshad/dotfiles ~/dotfiles
cd ~/dotfiles && git switch machine/workforce
stow ghostty zsh niri nvim tmux        # noctalia is no longer stowed, see Step 17i
```

> [!warning] Stow list is smaller than the branch package list
> The packages on `machine/workforce` are `btop fish ghostty hypr k9s niri noctalia nvim starship tmux zsh`. This build stows `ghostty zsh niri nvim tmux` (`noctalia` is not a stow package, Step 17i). `hypr` is dead weight (the target is niri), `fish` is unused (shell is zsh), `starship` is abandoned (prompt is Powerlevel10k, Step 18). Once `k9s` (Step 19d) and `btop` are installed, `stow k9s btop` too. Stow `ghostty` even before the terminal is installed; the config just waits.

> [!warning] The `niri` package was copied by hand from the other machine branch
> `machine/workforce` did not originally have a `niri` package:
> ```bash
> cd ~/dotfiles
> git switch machine/ri-t-0931 && cp -r niri ~/ && git switch machine/workforce && mv ~/niri .
> rm -rf ~/.config/niri            # let stow own it
> ```
> A plain `cp`, not `git cherry-pick`, so the two branches still diverge on purpose. Read the version-drift warning below before trusting anything in it.
>
> The `noctalia` package was regenerated the same way from `~/.config/noctalia` and **that turned out to be wrong**: Noctalia 5 does not use that path at all, so the package captured an empty tree. See Step 17i for what actually holds the config and how it is backed up.

> [!danger] A copied niri config carries the other machine's hardware AND its software versions
> Three separate things were silently broken by this copy, none of which produced an error at startup:
> 1. **Hardware:** `outputs.kdl` described a 1920x1200 VRR panel at scale 1.07 offset to `x=4880`. This machine is 1920x1080, no VRR, single output. niri fell back to the preferred mode without complaining. Fix by reading `niri msg outputs` and writing what it reports (Step 17f-2).
> 2. **niri version:** `Mod+Shift+R` called `niri msg action reload-config`, which no longer exists in niri 26.04 (renamed `load-config-file`). A `spawn` bind failing is invisible; the key just does nothing. Check every action against `niri msg action --help`.
> 3. **Noctalia version:** the whole IPC surface changed between 4 and 5 (Step 17a).
>
> After copying config from another machine, audit it against the local hardware and the locally installed versions before trusting any of it. `niri validate` passes on all three of these because they are all runtime lookups, not syntax.

> [!note] Keep `AGENTS.md` and the repo-root `CLAUDE.md` current
> Both were rewritten for this build (Debian testing, niri + Noctalia, greetd, Noctalia 5 IPC). On a future rebuild, re-check them against reality rather than trusting them blindly.

---

## 16 · Snapper & two-lane maintenance
*rollback net + the weekly pass across apt and Flatpak*

> [!danger] This step silently failed on the real build. Verify it, do not assume it.
> `create-config` was run and appeared to work, but months later `/etc/snapper/configs/` did not exist, `snapper list-configs` was empty, and `/.snapshots` was empty: **the machine had no rollback net at all** while the timers sat enabled and green. The likely cause is the `/.snapshots` entry written to `/etc/fstab` back in Step 06, which makes snapper's own subvolume creation conflict. Run the verification below and do not move on until it prints a config.

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

*Verify before moving on. All three must pass:*
```bash
sudo snapper list-configs                 # must list a 'root' config for /
test -f /etc/snapper/configs/root && echo "config file OK" || echo "FAILED: no config"
sudo snapper -c root create -d "verify" && sudo snapper -c root list   # must show the snapshot
```

> [!note] Debian already ships an apt hook, so do not write your own
> `/etc/apt/apt.conf.d/80snapper` comes from the `snapper` package and creates pre/post pairs around every apt transaction. It is guarded by `[ -e /etc/snapper/configs/root ]`, which is exactly why it does nothing when the config is missing: no error, no snapshots. Once `create-config` genuinely succeeds, the hook starts working with no further action. Overwriting this file with a hand-rolled `DPkg::Pre-Invoke` replaces a working pre/post pair with a worse one.

**Weekly, both lanes:**
```bash
sudo snapper -c root create -d "pre-update $(date +%F)"
sudo apt update
apt list --upgradable                 # skim before committing
sudo apt full-upgrade                 # 'full' handles testing's transitions too
sudo apt autoremove --purge
flatpak update && flatpak uninstall --unused
```

> [!warning] The release-day spike
> Because this machine tracks the `testing` alias, the weeks after any Debian stable release are the roughest patch in the cycle: the alias has just re-pointed at a newly opened suite, churn is at its highest, and security fixes lag most. Read `apt list --upgradable` properly in that window rather than skimming, and consider holding off entirely for a few weeks.

> [!danger] Rollback is manual with systemd-boot
> This is the tradeoff of choosing systemd-boot over GRUB+grub-btrfs: there are no auto-generated "boot into snapshot" menu entries. Recover from a live USB: mount the btrfs top level, `mv @ @broken`, `btrfs subvolume snapshot /.snapshots/<n>/snapshot @`, reboot. `@home` and `@snapshots` sit outside `@` and survive the swap; system-wide Flatpaks in `/var/lib/flatpak` are on `@` and roll back with it, so re-check them after a rollback.

---

---

## 17 · niri + Noctalia
*the daily driver: Noctalia from an apt repo, niri from source*

Do this after GNOME is stable, dotfiles are stowed, and snapper works. GNOME stays installed as a fallback session the whole time. This step is where the machine picks up a third software lane (a source build) on top of apt and Flatpak, and it is the one place it leaves the two-lane premise of Step 00.

### 17a · Noctalia from `pkg.noctalia.dev`

Noctalia (the shell), Umbriel (its sibling compositor), and the greeter all ship from one third-party apt repo, published by `nickh`. It is a normal Step 13 vendor repo: keyring, deb822 `.sources`, `Signed-By`.

```bash
sudo apt install -y curl wget

# keyring, delivered as a .deb that drops /usr/share/keyrings/nickh-archive-keyring.gpg
wget https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb
sudo dpkg -i nickh-archive-keyring.deb && rm nickh-archive-keyring.deb

# deb822 sources file, fetched straight from the repo
sudo wget -O /etc/apt/sources.list.d/noctalia-unstable.sources \
  https://pkg.noctalia.dev/deb/noctalia-unstable.sources

sudo apt update
sudo apt install -y noctalia noctalia-data noctalia-greeter
```

> [!note] What the `.sources` file contains
> `URIs: https://pkg.noctalia.dev/deb/`, `Suites: unstable/`, `Components:` empty (a flat repo), `Signed-By: /usr/share/keyrings/nickh-archive-keyring.gpg`, `Types: deb deb-src`. `Suites: unstable/` is the repo's own channel name, unrelated to Debian's `unstable`. Installed versions this build: `noctalia` / `noctalia-data` 5.0.1-1, `noctalia-greeter` 1.3.1-1.

> [!warning] `noctalia-greeter` takes over the display manager
> Its package enables `greetd` and adds `/usr/lib/systemd/system/greetd.service.d/noctalia-greeter.conf`, which makes greetd run the Noctalia graphical greeter. `display-manager.service` becomes an alias for `greetd`, and `gdm3` is demoted (`systemctl is-enabled gdm3` reports `alias`). This is intended. To go back to GNOME's login screen: `sudo systemctl disable greetd && sudo systemctl enable gdm3 && reboot`. `/etc/greetd/config.toml` itself is left at its stock `agreety` default; the drop-in is what matters.

> [!note] No standalone `quickshell` install
> `noctalia` depends on quickshell and pulls it in. The launch command is the `noctalia` binary at `/usr/bin/noctalia`, spawned from the niri autostart (`spawn-at-startup "noctalia"` in `~/.config/niri/autostart.kdl`), not `qs -c noctalia-shell`.

> [!warning] Noctalia 5 changed the IPC interface, and the dotfiles keybinds were written for 4
> v4 drove the shell with `qs -c noctalia-shell ipc call <object> <method>`. v5 dropped that entirely (`qs` is not even installed) for a flat `noctalia msg <verb>` set. The `niri` package on this branch was migrated in place: `binds.kdl` and the `swayidle` line in `autostart.kdl` now use `noctalia msg`. The mapping that was applied:
>
> | v4 `ipc call` | v5 `noctalia msg` |
> |---|---|
> | `launcher toggle` | `panel-toggle launcher` |
> | `launcher windows` | `window-switcher` |
> | `launcher emoji` | `panel-toggle launcher /emo` |
> | `launcher clipboard` | `panel-toggle clipboard` |
> | `settings toggle` | `settings-toggle` |
> | `calendar toggle` | `panel-toggle control-center calendar` |
> | `controlCenter toggle` | `panel-toggle control-center` |
> | `lockScreen lock` | `session lock` |
> | `sessionMenu toggle` | `panel-toggle session` |
> | `notifications toggleDND` | `notification-dnd-toggle` |
> | `mediaControls toggle` | `panel-toggle control-center media` |
>
> The structural change: **calendar and now-playing are control-center tabs in v5, not standalone panels.** The full tab list, from the `noctalia` binary's string table, is `home audio bluetooth calendar media monitor network notifications power system weather`. Standalone panels are only `launcher clipboard session wallpaper`. Verify with `noctalia msg --help` on the installed version; the `/emo` launcher context is the one token worth eyeballing after a rebuild.

> [!note] Umbriel is available from the same repo, not installed deliberately here
> This build also pulled `umbriel` (0.1.0, a second Wayland compositor) and `xdg-desktop-portal-umbriel`, and there is a `umbriel.desktop` session at the greeter. It came along with the repo rather than by choice. Keep it or `sudo apt purge umbriel xdg-desktop-portal-umbriel` if you want only niri. It does not affect niri either way.

### 17b · niri build dependencies

```bash
sudo apt install -y gcc clang libudev-dev libgbm-dev libxkbcommon-dev \
  libegl1-mesa-dev libwayland-dev libinput-dev libdbus-1-dev libsystemd-dev \
  libseat-dev libpipewire-0.3-dev libpango1.0-dev libdisplay-info-dev
```

### 17c · Rust toolchain

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
which cargo        # sanity check before building
```

`~/.zshenv`, `~/.bashrc`, and `~/.profile` already source `~/.cargo/env`, so new shells pick up cargo without this manual `source`.

### 17d · Build niri

```bash
git clone https://github.com/niri-wm/niri.git ~/niri-wm
cd ~/niri-wm
cargo build --release
```

> [!note] The repo moved
> niri is now at `github.com/niri-wm/niri`, not `github.com/YaLTeR/niri`. The old URL still redirects but clone the canonical one. This build produced `niri 26.04`.

### 17e · Install niri into `/usr/local`

Everything niri needs to be a selectable session lives in `resources/` in the source tree.

```bash
cd ~/niri-wm

sudo cp target/release/niri /usr/local/bin/

sudo mkdir -p /usr/local/share/wayland-sessions
sudo mkdir -p /usr/local/share/xdg-desktop-portal

sudo cp resources/niri-session          /usr/local/bin/
sudo cp resources/niri.desktop          /usr/local/share/wayland-sessions/
sudo cp resources/niri-portals.conf     /usr/local/share/xdg-desktop-portal/
sudo cp resources/niri.service          /etc/systemd/user/
sudo cp resources/niri-shutdown.target  /etc/systemd/
```

> [!warning] `/usr/local` overrides, it does not merge
> Debian would put these under `/usr/share` and `/lib/systemd` if niri were packaged. Installing to `/usr/local` and `/etc/systemd/user` keeps the source build clearly separate and higher priority. On a niri version bump: `git pull`, `cargo build --release`, and re-run every `cp` above.

### 17f · Session entry

Pick "niri" at the greeter. `niri.desktop` in `/usr/local/share/wayland-sessions/` (copied in Step 17e) is `Exec=niri-session`, so the greeter runs the session wrapper directly and there is nothing else to configure. GNOME stays one menu entry away.

`niri-session` is the part that matters: it registers `org.gnome.Mutter.ScreenCast` on the bus so `xdg-desktop-portal-gnome` can do window and monitor capture. Launching plain `niri` skips that and browsers loop the screen-share permission dialog. `autostart.kdl` then restarts the portal once the session env is exported.

> [!note] No launcher script needed
> An earlier version of the dotfiles carried a `start-niri.sh` that exported `XDG_CURRENT_DESKTOP` and exec'd `niri-session` from `~/.zprofile` on VT1. With a greeter in place that is redundant (the session file already does both) and it has been removed. If you ever want TTY autostart back, recover it from git history.

### 17f-2 · Outputs and scaling

`outputs.kdl` on this branch configures exactly one output, the built-in panel:

```kdl
output "eDP-1" {
    mode "1920x1080@59.999"
    scale 1.25
}
```

> [!warning] Check the panel before copying an `outputs.kdl` between machines
> This block came over from the other machine branch describing a 1920x1200 panel with VRR at scale 1.07, positioned at `x=4880` to sit beside an ultrawide. On this T490 the panel is a BOE 0x07DB at **1920x1080** with only two modes and **no VRR**, so the configured mode did not exist and niri silently fell back to preferred. Verify with `niri msg outputs` and match `mode`, `scale`, and VRR to what it actually reports. Drop `position` entirely when there is only one output.
>
> Keep `QT_FONT_DPI` in `environment.kdl` in step with the scale: 96 × 1.25 = 120.

### 17g · awww wallpaper daemon (source build)

`autostart.kdl` spawns `awww-daemon` and `wallpaper.sh` drives it (`awww query`, `awww img … --transition-type fade`). `awww` is LGFae's maintained successor to `swww` (swww is archived; do not "fall back" to it). It is not in the Debian archive, so it is a source build like niri.

```bash
# build deps the niri build did not already cover
sudo apt install -y wayland-protocols cmake

git clone https://codeberg.org/LGFae/awww ~/awww
cd ~/awww
cargo build --release

sudo cp target/release/awww target/release/awww-daemon /usr/local/bin/
awww --version        # expect: awww 0.12.1
```

> [!warning] The original build failed on a missing `wayland-protocols`, not on lz4
> The first attempts on this machine failed and `liblz4-dev` / `librust-lzzzz-dev` were installed chasing the error message. That was a red herring: awww bundles lz4 through the pure-Rust `lzzzz` crate. The real stopper was `wayland-protocols` (awww runs `wayland-scanner` over `wlr-layer-shell` and `viewporter` XML from that package), plus `cmake` for a `-sys` crate. `pkg-config` the package is not needed; `pkgconf` provides the shim. awww's MSRV is 1.87, well under the installed toolchain.

> [!note] awww needs `wlr-layer-shell`
> It runs under niri (which implements the protocol) and will not run under GNOME. That is fine: the wallpaper is a niri-session concern only.

### 17h · Glass effect needs a wallpaper underneath

Noctalia panel glass and niri window blur both read the **wallpaper layer**, not the windows behind. With no wallpaper set they frost a solid black surface, which looks flat and murky rather than frosted. On this build the glass settings were already correct and the wallpaper was the missing half:

```
awww query   ->  currently displaying: color: 000000
```

The settings involved, all correct once a wallpaper exists:

- `~/.local/state/noctalia/settings.toml`: `[backdrop] enabled = true` and `[shell.panel] transparency_mode = "glass"`
- `niri/.config/niri/rules.kdl`: `background-effect { xray true; blur true; noise 0.15; saturation 1.4 }` (needs niri 26.04+)

`xray true` is the key line: it blurs the wallpaper rather than the windows behind, which is the macOS vibrancy look and exactly why an empty wallpaper kills the effect.

> [!danger] The Unsplash key path used to resolve inside the public repo
> `wallpaper.sh` originally read `$HOME/.config/niri/unsplash-key`. `~/.config/niri` is a **stow symlink into the dotfiles repo**, so that path resolved to `~/dotfiles/niri/.config/niri/unsplash-key`: the key would have been one `git add -A` away from being published. The script now reads `~/.config/secrets/unsplash-key`, outside the stowed tree, and `.gitignore` carries `**/unsplash-key` as a safety net. Check for this trap whenever a script under a stowed directory reads a credential.

```bash
mkdir -p ~/.config/secrets
echo "YOUR_UNSPLASH_ACCESS_KEY" > ~/.config/secrets/unsplash-key
chmod 600 ~/.config/secrets/unsplash-key

# restart the rotator; it waits for awww-daemon then sets a wallpaper every 5 min
bash ~/.config/niri/wallpaper.sh &
awww query        # should now show an image path, not color: 000000
```

> [!note] `wallpaper.sh` parses JSON with `jq`, not `python3`
> The original used a `python3 -c` one-liner to pull `.urls.raw` from the Unsplash response. It now uses `jq -r '.urls.raw // empty'`, the right tool for a single-field extraction, and drops a Python dependency from the session startup path.

Tune the frosting with `backdrop.blur_intensity` and `backdrop.tint_intensity` in `settings.toml`; both are unset here and running at defaults.


### 17i · Noctalia config lives outside `~/.config`, and is backed up encrypted

> [!danger] Noctalia 5 moved its config, and the old stow package silently backed up nothing
> v4 kept everything in `~/.config/noctalia`. **v5 uses `~/.local/state/noctalia/`.** The `noctalia` stow package on this branch still pointed at the v4 path, so after the upgrade it contained zero files while `~/.config/noctalia` was a symlink to an empty directory. Nothing errored; the config simply was not being tracked. The dead package and symlink have been removed.

The live config is `~/.local/state/noctalia/settings.toml`, holding the theme, panel transparency, bar layout, lockscreen widgets, the `[plugins] enabled` list, and (once configured) a `plugin_settings.<id>` table per plugin.

> [!danger] `plugin_settings` holds plaintext credentials and this repo is public
> Enabled plugins declare settings like `api_key` / `api_secret` (`davemhammer/opnsense`), `api_key` (`rylos/syncthing`), and `kubeconfig` (`davemhammer/k8s-status`). Their values are written straight into `settings.toml`. Never commit that file as-is.

The file is therefore tracked **encrypted with SOPS**, not stowed:

```bash
# one-time: generate the age key ~/.zshrc already points SOPS_AGE_KEY_FILE at
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
# put the printed public key in .sops.yaml under creation_rules

# capture the current config
cp ~/.local/state/noctalia/settings.toml noctalia/settings.sops.toml
sops --encrypt --in-place noctalia/settings.sops.toml

# restore on a rebuild
mkdir -p ~/.local/state/noctalia
sops --decrypt noctalia/settings.sops.toml > ~/.local/state/noctalia/settings.toml
noctalia msg config-reload
```

> [!warning] Back the age private key up somewhere outside this repo
> `~/.config/sops/age/keys.txt` is the only way to read `noctalia/settings.sops.toml`. It is mode 600 and lives outside the repo. Lose it and the encrypted config is unrecoverable. `.gitignore` also carries `noctalia/settings.toml` so a stray decrypt cannot be committed by accident.

> [!note] SOPS encrypts this file as an opaque blob
> SOPS has no TOML parser, so it falls back to binary mode: the whole file is one ciphertext value rather than per-key encryption. It round-trips correctly, but every change rewrites the entire blob, so git diffs on it are not readable. That is acceptable for a settings file you edit through a GUI.

**Plugin settings are entered through the GUI**, not the CLI: `noctalia msg settings-open-plugin <author/plugin>`. There is no `noctalia msg` verb that writes a plugin setting, so credentials never need to pass through a shell history or a terminal.
---

## 18 · Shell environment
*zsh framework, prompt, plugins, version manager*

The `zsh` package and `chsh` were done back in Step 15. This step is everything the interactive shell sits on. The dotfiles `zsh` package supplies `~/.zshrc`; these installs are what it expects to find.

```bash
# oh-my-zsh (unattended)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Powerlevel10k theme (~/.zshrc sets ZSH_THEME="powerlevel10k/powerlevel10k")
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# custom plugins ~/.zshrc loads by name
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/you-should-use"
git clone https://github.com/fdellwing/zsh-bat.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-bat"

# syntax highlighting from apt, sourced by absolute path at the end of ~/.zshrc
sudo apt install -y zsh-syntax-highlighting

# CLI helpers ~/.zshrc and its aliases use
sudo apt install -y fzf eza bat

# the kubectl/helm wrapper functions in ~/.zshrc call `command kubecolor` and
# read $KUBIE_CTX; without kubecolor a plain `kubectl` errors in an interactive
# shell. Both are in the archive.
sudo apt install -y kubecolor kubie
```

> [!note] Smaller `~/.zshrc` loose ends
> `zsh-history-substring-search` is in the `plugins=(...)` list but was not cloned (it is also an apt package of that exact name). `zsh-completions` is added to `fpath` but not cloned. Neither breaks the shell; add them if the missing completions or history search bother you.

> [!note] `starship` is not used
> There is a `starship/` stow package in the repo, but the prompt is Powerlevel10k (`ZSH_THEME` in `~/.zshrc`) and nothing invokes starship. Do not install it and do not stow the package; treat it as abandoned unless the prompt choice changes.

> [!note] mise and its activation
> `mise` was installed in Step 15 via `curl https://mise.run | sh` to `~/.local/bin/mise`. `~/.zshrc` runs `eval "$(mise activate zsh)"` before `source $ZSH/oh-my-zsh.sh`. No tools are mise-managed yet (`mise ls` is empty); it is wired but idle.

## 19 · Containers & Kubernetes tooling
*Docker CE, kubectl, the SOPS/age pair*

### 19a · Docker CE

```bash
# get.docker.com in REPO_ONLY mode just adds the apt repo + keyring, no install
curl -fsSL https://get.docker.com | sudo REPO_ONLY=1 sh

sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker naeem      # re-login for this to take effect
```

> [!warning] The Docker repo targets `trixie`, not `forky`
> Docker publishes for Debian stable codenames only. On this build `/etc/apt/sources.list.d/docker.list` ends up as `... https://download.docker.com/linux/debian trixie stable` and the installed packages carry `~debian.13~trixie` version tags. An earlier attempt wrote a deb822 `docker.sources` with `Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")`, which expands to `forky` on this machine, a suite Docker does not publish, so that file was deleted. `get.docker.com` gets the codename right. If you hand-write the repo, pin it to `trixie`.

### 19b · kubectl

```bash
sudo apt install -y apt-transport-https ca-certificates curl gnupg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

sudo apt update && sudo apt install -y kubectl
```

The repo is pinned to the `v1.37` line. Bumping minor versions means editing both the keyring URL and the list file to the new `v1.NN`.

### 19c · Secrets and the rest

```bash
sudo apt install -y age

# sops is NOT in the Debian archive on this suite: `sudo apt install sops`
# fails. Take the release binary into /usr/local/bin.
curl -fsSL -o /tmp/sops \
  https://github.com/getsops/sops/releases/latest/download/sops-v3.13.3.linux.amd64
sudo install -m0755 /tmp/sops /usr/local/bin/sops && rm /tmp/sops
sops --version        # expect: sops 3.13.3
```

`~/.zshrc` sets `SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt`, so `age` alone is not enough. On this build `age` came from apt (1.3.1) and `sops` (3.13.3) was installed by hand to `/usr/local/bin`; adjust the version in the URL to whatever `github.com/getsops/sops/releases/latest` currently points at.

### 19d · k9s

Not in the Debian archive (`sudo apt install k9s` fails). The upstream release ships a `.deb`:

```bash
curl -fsSLO https://github.com/derailed/k9s/releases/download/v0.51.0/k9s_linux_amd64.deb
sudo apt install -y ./k9s_linux_amd64.deb && rm k9s_linux_amd64.deb
k9s version
```

The `k9s/` stow package supplies `~/.config/k9s/` (config, aliases, catppuccin-latte skin). Bump the version in the URL as new releases land; `apt install ./file.deb` keeps it dpkg-tracked so `apt list --installed | grep k9s` still shows it.

> [!note] Also installed here, machine-specific
> Docker Sandboxes (`sbx`): a downloaded `.deb` (`DockerSandboxes-linux-amd64-ubuntu2604.deb`) via `sudo apt install ./<file>.deb`.

## 20 · Virtualization
*qemu + libvirt for local VMs and Vagrant*

```bash
sudo apt install -y qemu-system libvirt-daemon-system
sudo usermod -aG libvirt naeem     # re-login for this to take effect
```

`~/.zshrc` sets `VAGRANT_DEFAULT_PROVIDER=libvirt`, so Vagrant (installed separately when needed) uses this stack rather than VirtualBox.

## 21 · Editors & desktop apps
*the GUI layer that is not part of the desktop shell*

```bash
# Zed: upstream installer, lands in ~/.local/zed.app, symlink in ~/.local/bin
curl -f https://zed.dev/install.sh | sh

# Claude Code: upstream installer, into ~/.local/share/claude, symlink in ~/.local/bin
curl -fsSL https://claude.ai/install.sh | bash

# Claude Desktop: a real apt repo
sudo apt install -y curl gnupg
sudo curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc \
  https://downloads.claude.ai/claude-desktop/key.asc
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
  | sudo tee /etc/apt/sources.list.d/claude-desktop.list
sudo apt update && sudo apt install -y claude-desktop

# Obsidian: downloaded .deb
sudo apt install ~/Downloads/obsidian_*_amd64.deb

# small stuff
sudo apt install -y gnome-tweaks fastfetch fuzzel alacritty
```

> [!note] `claude-memory-extractor`
> Cloned to `~/claude-memory-extractor` (`git clone https://github.com/naimarshad/claude-memory-extractor.git`). Its `install.sh` wires the `SessionStart` / `SessionEnd` hooks into `~/.claude/`. Run it once after the clone.

> [!note] `fuzzel` is the niri launcher
> niri binds expect `fuzzel`; `alacritty` is a fallback terminal to `ghostty`. Neither matters under GNOME, both matter after Step 17.

## 22 · Sync & networking
*file sync and VPN tooling*

```bash
sudo apt install -y syncthing wireguard-tools

systemctl --user enable --now syncthing
```

> [!note] Referenced by the niri autostart, install when you get to them
> `autostart.kdl` spawns `seafile-applet` and `/usr/lib/kdeconnectd` + `/usr/bin/kdeconnect-indicator`. Seafile client and `kdeconnect` are separate installs (kdeconnect is in the archive; a firewall still needs TCP+UDP `1714-1764`). They are not desktop-critical and were not part of the core build.

---

## Restore checklist
- [ ] correct device confirmed with `lsblk` before `sgdisk --zap-all`
- [ ] GPT created · 1 GiB ESP (`ef00`) · root partition (`8300`) · both formatted
- [ ] btrfs subvolumes created and mounted · `/mnt/debian/efi` mounted
- [ ] deb822 sources with `Suites: testing` · machine-id before kernel
- [ ] `/etc/kernel/cmdline` has `root=UUID` + `rootflags=subvol=@`
- [ ] `systemd-boot` installed · `bootctl list` shows the kernel
- [ ] `efibootmgr` shows Linux Boot Manager first
- [ ] `firmware-iwlwifi` installed · WiFi card seen by `lspci`
- [ ] `openssh-server` and `systemd-timesyncd` installed · all three units report `enabled` before rebooting
- [ ] `gnome-core` installed WITHOUT `--no-install-recommends` · gdm3 enabled · add-ons · portals · fonts
- [ ] theming: `qt6ct` + `bibata-cursor-theme` from apt · `adw-gtk3` built from source (needs `meson` + standalone `dart-sass`) · **gsettings `gtk-theme` and `cursor-theme` actually set**, not just installed
- [ ] third-party repos added (keyring + `Signed-By`, pinned) · Flatpak (system-wide) apps restored
- [ ] dotfiles stowed (`ghostty zsh niri noctalia nvim tmux`) · `niri` + `noctalia` packages rebuilt · large diff committed per file
- [ ] snapper: `snapper list-configs` actually lists `root` and a test snapshot appears · timers enabled (this step silently failed once, verify it)
- [ ] Step 17a: Noctalia repo added · `noctalia noctalia-data noctalia-greeter` installed · greetd now `display-manager.service`
- [ ] Step 17b-e: niri build deps · rustup · `cargo build --release` · binary + resources copied to `/usr/local`
- [ ] Step 17f: "niri" selectable at the greeter · `outputs.kdl` mode/scale/VRR matched to `niri msg outputs`, not inherited from another machine · `QT_FONT_DPI` in step with the scale
- [ ] Step 17g: `wayland-protocols` + `cmake` installed · `awww` built · `awww` + `awww-daemon` in `/usr/local/bin`
- [ ] Step 17h: a real wallpaper is set (`awww query` is not `color: 000000`) or glass will frost black · Unsplash key at `~/.config/secrets/`, NOT under stowed `~/.config/niri/`
- [ ] Step 17i: `noctalia/settings.sops.toml` committed encrypted · age key at `~/.config/sops/age/keys.txt` backed up off-repo · plaintext `settings.toml` gitignored
- [ ] Step 18: oh-my-zsh + p10k + plugins · `kubecolor` + `kubie` from apt · `starship` deliberately skipped
- [ ] Step 19: Docker repo pinned to `trixie` · `docker`/`libvirt` groups added · `sops` release binary in `/usr/local/bin` · `k9s` `.deb` from upstream
- [ ] Steps 20-22: qemu/libvirt · Zed / Claude Desktop / Claude Code / Obsidian · syncthing user service · `claude-memory-extractor` install.sh run
- [ ] `AGENTS.md` and repo-root `CLAUDE.md` re-checked against the finished machine (Debian testing / niri / Noctalia)

---
*Debian testing (rolling alias) · GNOME first boot, then niri (source) + Noctalia (apt repo) · greetd · systemd-boot · btrfs/snapper · Rev. 4*
