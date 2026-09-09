---
title: "Arch Linux + niri Install Runbook"
aliases: ["Arch Runbook", "T490 Arch Migration Runbook", "Arch niri Rev 2"]
tags: [arch, niri, noctalia, systemd-boot, btrfs, luks, runbook, thinkpad-t490]
machine: "ThinkPad T490 (20N2004AGE)"
arch: "x86_64"
init: "systemd + systemd-boot"
filesystem: "btrfs + snapper on LUKS2"
desktop: "GNOME (Wayland) first boot, then niri (extra repo) + Noctalia (extra repo)"
display-manager: "gdm for the GNOME phase, then greetd + noctalia-greeter"
method: "pacstrap (manual, from the official Arch ISO on a live USB)"
supersedes: "Debian Testing - GNOME Install Runbook.md (now in archived/)"
rev: "2"
status: "verified record"
---

# Arch Linux + niri: a rolling binary-native daily driver

**Arch Linux**, installed by hand with `pacstrap` from the official ISO on a live USB, onto an encrypted btrfs + snapper + systemd-boot spine. The daily driver is **niri** (Wayland scrolling compositor) with **Noctalia 5** as the shell, both installed from the official `extra` repository rather than built from source.

> [!info] Legend
> `[!warning]` = a gotcha to get right · `[!success]` = a win over the Debian build · `[!danger]` = can lock you out / data loss · `[!note]` = info.

> [!note] This is a verified record
> The `workforce` T490 was installed from this runbook on 2026-09-06. Every step below was then reconciled against the running system, `~/.bash_history`, and `~/.zsh_history`, and the corrections found on the day are folded in. Things that broke, were skipped, or drifted on the first pass are called out inline with `[!warning] On the workforce build`. Package names and versions still drift, so the "verify at install time" notes stay.

> [!success] The source-build lane is gone
> Rev 4 needed a third software lane for the two things Debian could not ship prebuilt: niri and awww, both `cargo build --release` from source, plus a standalone `dart-sass` for the GTK theme. On Arch, `niri`, `ghostty`, `k9s`, `awww`, `kubie`, and the GTK theme are all in `extra`. Noctalia 5 is in `extra`. What remains outside the official repos is a short AUR tail (`noctalia-greeter`, `bibata-cursor-theme`, `kubecolor`, `claude-desktop`, `zen-browser-bin`), handled through `paru` with the trust discipline in Step 14. **Two lanes carry everything: pacman (official repos) and AUR (small, audited).** This build uses no Flatpak at all: see Step 20.

## Facts

- Disk: `/dev/nvme0n1`, wiped, GPT created fresh in Step 02
- ESP: `/dev/nvme0n1p1` (vfat, **2 GiB**, mounted at `/boot`, holds two kernels + fallback initramfs, unencrypted)
- LUKS2 container: `/dev/nvme0n1p2`, opened as `/dev/mapper/cryptroot`, passphrase unlock at boot
- Root fs: btrfs inside `/dev/mapper/cryptroot`, label `arch` · subvols `@ @home @log @snapshots`
- Mount opts: `compress=zstd:3,noatime`
- Swap: **zram only** (`zram-generator`, ~half of RAM, zstd). No disk swap, no hibernation.
- Kernels: `linux` (default) and `linux-lts` (fallback boot entry)
- Bootloader: systemd-boot (part of `systemd`, no separate package) · Init: systemd
- Encryption unlock: `sd-encrypt` initramfs hook + `rd.luks.name=` on the kernel cmdline. TPM2 auto-unlock is deliberately not set up; it can be added later with `systemd-cryptenroll` without reinstalling.
- WiFi: Intel, covered by `linux-firmware` (one package on Arch, no `firmware-iwlwifi` split)
- Display manager: `gdm` during the GNOME phase, `greetd` + `noctalia-greeter` after Step 22
- Compositor: `niri` from `extra` (`pacman -S niri`, currently 26.04) · shell: `noctalia` from `extra` (currently 5.x)
- Hostname: `workforce` · timezone: `Europe/Berlin` · locales: `en_US.UTF-8` + `de_DE.UTF-8`
- Git identity for the dotfiles repo, set `--local`: `Naeem Arshad <naimarshad@gmail.com>`

## Mapping to the Debian runbook (Rev 4)

| Rev 4 | This runbook | What changes |
|---|---|---|
| 01 live env (debootstrap) | 01 | Official Arch ISO, `iwctl`, `reflector` for mirrors |
| 02 partition | 02 | ESP grows 1 GiB to 2 GiB; partition 2 becomes a LUKS container |
| (none) | 03 | **New:** LUKS2 `luksFormat` / `open` |
| 03 btrfs subvols | 04 | Same flat `@ @home @log @snapshots`, now inside `/dev/mapper/cryptroot` |
| 04 debootstrap + sources | 05 | `pacstrap -K`, `genfstab` (removes the unquoted-heredoc fstab gotcha) |
| 06 fstab/time/locale | 06 | `genfstab -U` then edits; same hostname/tz/locale |
| 05 chroot | 07 | `arch-chroot /mnt` (one command, handles all the bind mounts) |
| 07 kernel + systemd-boot | 08 + 09 | `mkinitcpio` with `sd-encrypt`; manual loader entries (no auto-generation on Arch systemd-boot) |
| 08 users/sudo/network | 10 | `wheel` group + sudoers; `sshd.service` not `ssh.service`; `systemd-timesyncd` is part of `systemd` |
| (none) | 11 + 12 | **New:** `reflector` + `pacman.conf` tuning; `zram-generator` |
| 09 first reboot | 13 | Same |
| (none) | 14 | **New:** `paru` bootstrap + the AUR lane discipline (parallels Rev 4 Step 13's `.deb` lane) |
| 10-12 GNOME + add-ons + essentials | 15-17 | `gnome` metapackage tiers differ; portals and fonts are the same idea |
| 12 theming | 18 | `adw-gtk-theme` from a repo, no `dart-sass` / `meson` source build; **gsettings must still be set** |
| 13 third-party `.deb` lane | folded into 14 + inline | Replaced by pacman official repos + the AUR lane |
| 16 snapper | 19 | Same flat-layout dance and the same verification; `snap-pac` replaces Debian's apt hook |
| 14 Flatpak | 20 | **Dropped:** no Flatpak; Zen browser from AUR (`zen-browser-bin`) |
| 15 dotfiles + stow | 21 | `ghostty` and `mise` now packaged; same `stow` set |
| 17 niri + Noctalia | 22 | **Biggest change:** `pacman -S niri noctalia`; Steps 17b-17e (source build) deleted; `noctalia-greeter` from AUR |
| 18 shell env | 23 | Same; `kubie` from `extra`, `kubecolor` from AUR |
| 19 containers/k8s | 24 | `docker` not `docker-ce`; `kubectl`, `k9s`, `sops` mostly packaged |
| 20-22 virt / apps / sync | 25-27 | Same tools, `pacman` / AUR instead of apt / installer scripts |
| 21 `claude-memory-extractor` note | 28 | **Expanded into its own step:** deps before `install.sh`, the per-machine routing config `install.sh` will not restore, the MEMORY.md freeze guard that lives only in your `settings.json` backup |

---

## 00 · Strategy · rolling, binary-native, two lanes

Everything installs prebuilt. On Arch you almost never read about compile flags; you read about **which repo a package comes from**. Two lanes carry all software, in order of preference:

1. **pacman, official repos** (`core`, `extra`, `multilib` if enabled): the Arch archive, huge and prebuilt. This is where `niri`, `noctalia`, `ghostty`, `k9s`, `awww`, `kubie`, `docker`, `kubectl` now live, all of which were a source build, an installer script, or a downloaded `.deb` on Debian.
2. **AUR** (via `paru`): user-submitted build recipes for the handful of things not in the official repos. Small, audited, and reviewed on every update. Step 14 covers the trust model.

Rev 4 also ran a system-wide **Flatpak** for the Zen browser. This build drops Flatpak entirely: Zen comes from the AUR (`zen-browser-bin`), so there is no third lane and no `/var/lib/flatpak` to reason about during a snapshot rollback.

> [!warning] Rolling discipline: read the news, never partial-upgrade
> Arch has no testing/stable split and no migration filter. Updates land when upstream ships them. Two habits replace Debian's `apt-listbugs` skim:
> 1. **Read `https://archlinux.org/news/` before every `pacman -Syu`.** Manual-intervention notices (a config move, a package split, a keyring bump) are posted there and nowhere else. `informant` (`extra`) is installed on this machine in Step 13 and blocks an upgrade until the news is marked read.
> 2. **Never partial-upgrade.** `pacman -Sy <pkg>` without a full `-Syu` gives you a package built against libraries newer than the ones on disk, and that is the classic way to break a running Arch system. Always `pacman -Syu`, all or nothing.
> Snapper (Step 19) matters *more* here than on testing, not less: snapshot before every upgrade.

> [!note] Verify names, don't guess
> Confirm packages with `pacman -Ss <term>` (official) and `paru -Ss <term>` (AUR) before installing. Confirmed in `extra` on the workforce build (2026-09-06): `niri` 26.04, `noctalia` 5.0.1, `ghostty`, `k9s`, `awww` 0.12.1, `kubie` 0.28, `mise`, `sops`, `age`, `zed`, `zram-generator`, `snap-pac`, `adw-gtk-theme`, `informant`, `btop`, `alacritty`, `bluez-utils`, `kdeconnect`, `libnotify`. From the AUR: `noctalia-greeter` 1.3.1, `bibata-cursor-theme`, `kubecolor`, `claude-desktop`, `zen-browser-bin`, `ttf-amiri`, `gnome-shell-extension-gsconnect`, `seafile-client`, `arch-update`. `swww` is in `extra` too, but this build uses `awww`.

## 01 · Live environment & tooling
*boot the official Arch ISO from a live USB, get network, refresh mirrors*

Write the current ISO to a USB stick (`dd`, Ventoy, or Rufus on another machine) and boot it. The ISO already carries `pacstrap`, `arch-chroot`, `genfstab` (from `arch-install-scripts`), `btrfs-progs`, `cryptsetup`, `gdisk`, and `reflector`.

*live env, as root*
```bash
# keyboard, if not US
loadkeys de-latin1        # or skip for US

# network: wired is automatic. For WiFi:
iwctl
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect "SSID"
[iwd]# exit
ping -c2 archlinux.org

# clock
timedatectl set-ntp true

# fast mirrors, Germany first (writes /etc/pacman.d/mirrorlist)
reflector --country Germany --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# optional: let yourself in over SSH and work in tmux
passwd                    # sets the live env root password
systemctl start sshd
ip -brief addr            # note the address to SSH to
```

> [!note] Verify boot mode is UEFI
> `cat /sys/firmware/efi/fw_platform_size` should print `64`. If the file is missing you booted in BIOS/CSM mode; fix it in the firmware menu before partitioning, because systemd-boot is UEFI-only.

## 02 · Partition the blank disk
*GPT, a 2 GiB ESP, and the rest as a LUKS container*

> [!danger] This destroys everything on the target device
> Confirm the device name before every command. On this machine the internal disk is `nvme0n1`, but a USB stick can shift enumeration. `lsblk` first, every time, and match the size to the internal disk.

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
```

*create a fresh GPT with two partitions*
```bash
wipefs -a /dev/nvme0n1              # clear stale filesystem signatures
sgdisk --zap-all /dev/nvme0n1      # drop any existing GPT and MBR

sgdisk -n 1:0:+2G -t 1:ef00 -c 1:"EFI System"  /dev/nvme0n1
sgdisk -n 2:0:0   -t 2:8309 -c 2:"Linux LUKS"  /dev/nvme0n1

partprobe /dev/nvme0n1
lsblk /dev/nvme0n1                  # p1 = 2G, p2 = the rest
```

*format the ESP now; p2 gets formatted inside the LUKS container in Step 04*
```bash
mkfs.vfat -F 32 -n ESP /dev/nvme0n1p1
```

> [!note] Why the ESP is 2 GiB and mounted at `/boot`, not `/efi`
> This build keeps kernels and initramfs on the ESP (`/boot`) so there is nothing to copy or sync when a kernel updates. Two kernels (`linux`, `linux-lts`), each with a standard and a fallback initramfs, plus microcode, run around 300 to 500 MB. 2 GiB leaves comfortable slack. `/boot` being unencrypted is inherent to the "encrypt root, plain ESP" model chosen here; closing that gap needs a signed UKI with Secure Boot, which is deliberately out of scope.

## 03 · LUKS2 container
*encrypt partition 2, open it as `cryptroot`*

```bash
cryptsetup luksFormat --type luks2 --label CRYPTROOT /dev/nvme0n1p2
# type YES, then set the passphrase twice

cryptsetup open /dev/nvme0n1p2 cryptroot
ls /dev/mapper/cryptroot           # must exist before Step 04
```

> [!note] luks2 defaults are fine
> `cryptsetup` on a current ISO defaults to LUKS2 with Argon2id key derivation and a 512-bit key (aes-xts-plain64). No extra flags needed. Keep the passphrase somewhere recoverable: it is the only way in, and no recovery key is enrolled by default. To add a second passphrase later: `cryptsetup luksAddKey /dev/nvme0n1p2`.

> [!warning] The UUID you need in Step 09 is the container's, not the filesystem's
> `blkid /dev/nvme0n1p2` gives the LUKS *container* UUID (`TYPE="crypto_LUKS"`). That is what goes in `rd.luks.name=<UUID>=cryptroot`. The btrfs UUID inside `/dev/mapper/cryptroot` is a different value and is not used on the cmdline.

## 04 · btrfs subvolumes & mount layout
*flat subvolume layout, identical to Rev 4, inside the encrypted container*

```bash
mkfs.btrfs -L arch /dev/mapper/cryptroot

mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@snapshots
umount /mnt

mount -o subvol=@,compress=zstd:3,noatime /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,home,var/log,.snapshots}
mount -o subvol=@home,compress=zstd:3,noatime      /dev/mapper/cryptroot /mnt/home
mount -o subvol=@log,compress=zstd:3,noatime       /dev/mapper/cryptroot /mnt/var/log
mount -o subvol=@snapshots,compress=zstd:3,noatime /dev/mapper/cryptroot /mnt/.snapshots
mount /dev/nvme0n1p1 /mnt/boot
```

> [!note] Why `@home` is separate, and why the layout stays flat
> Same reasoning as Rev 4: a Step 19 rollback swaps a broken `@` for a snapshot and leaves `@home` and `@snapshots` untouched. The flat layout (rather than the openSUSE-style nested `@/.snapshots/N/snapshot` with a default-subvol switch) is a deliberate carry-over. It keeps this runbook comparable to Rev 4 and keeps rollback as an explicit, understood, manual operation. The cost is the same as on Debian: no single-command rollback, and the `create-config` interaction in Step 19 that must be verified rather than assumed.

## 05 · Bootstrap the base system
*`pacstrap` the base, kernels, and the packages the first boot depends on*

```bash
pacstrap -K /mnt \
  base base-devel \
  linux linux-lts linux-firmware intel-ucode \
  btrfs-progs cryptsetup mkinitcpio \
  sudo networkmanager openssh \
  git vim zsh
```

> [!warning] `base` does not include a kernel or a bootloader
> `base` is a minimal package set only. `linux` (and here `linux-lts`) must be listed explicitly. systemd-boot is not a package: it ships inside `systemd`, which `base` pulls in, and is installed by running `bootctl install` in Step 09.

> [!danger] No `openssh` here means no remote finish
> Step 13 reboots and finishes the desktop over SSH. The `sshd` running now belongs to the live ISO, not to the system being built. `openssh` provides `sshd.service` on Arch (not `ssh.service` as on Debian). Skip it and you reboot into a machine you can only use at the keyboard.

*generate fstab*
```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab                  # sanity check: four btrfs lines + one vfat /boot line
```

> [!success] `genfstab` removes the Rev 4 heredoc gotcha
> Rev 4 hand-wrote fstab with an unquoted heredoc so `$(blkid …)` expanded. `genfstab -U` reads the live mounts and writes real UUIDs directly. The four subvolume mounts all carry the same btrfs UUID (they are one filesystem); that is correct.

## 06 · fstab · time · locale · hostname
*edits inside the freshly bootstrapped tree*

```bash
# timezone
ln -sf /mnt/usr/share/zoneinfo/Europe/Berlin /mnt/etc/localtime

# locale: uncomment en_US.UTF-8 and de_DE.UTF-8
sed -i 's/^#\(en_US.UTF-8\|de_DE.UTF-8\)/\1/' /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

# console keymap (matches Step 01)
echo "KEYMAP=us" > /mnt/etc/vconsole.conf   # or de-latin1

# hostname + hosts
echo "workforce" > /mnt/etc/hostname
cat > /mnt/etc/hosts <<'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   workforce.localdomain workforce
EOF
```

`hwclock` and `locale-gen` run inside the chroot in the next step, where they can see the system clock and the C library.

> [!warning] On the workforce build: an invalid `KEYMAP` fails a boot service every boot
> The first pass wrote `KEYMAP=us-latin1`, which is not a real keymap (the valid names are `us` and `de-latin1`, not a blend). `systemd-vconsole-setup.service` then failed on every boot with `loadkeys: Unable to open file: us-latin1`, showing "Failed to start Virtual Console Setup" in the boot log. It only affects the text VTs, not the niri session, but it is a red failed unit. Check the value against `localectl list-keymaps` and confirm `systemctl status systemd-vconsole-setup.service` is clean after first boot.

> [!note] Tighten the ESP mount permissions in fstab
> `genfstab` writes the `/boot` vfat line with `fmask=0022,dmask=0022`, which leaves `/boot` world-readable. `bootctl` then warns on every boot that `/boot/loader/random-seed` is "world accessible, which is a security hole". Edit the `/boot` line in `/mnt/etc/fstab` to `fmask=0077,dmask=0077`, and delete a stale `/boot/loader/random-seed` if one already exists (systemd-boot regenerates it with correct perms).

## 07 · Enter the chroot
```bash
arch-chroot /mnt

# one-time setup that needs to run inside the target
hwclock --systohc
locale-gen
```

> [!success] `arch-chroot` replaces the Rev 4 bind-mount dance
> Rev 4 hand-mounted `/proc`, `/sys`, `/dev`, `/run` with `--rbind` / `--make-rslave` before `chroot`. `arch-chroot` does all of that, copies `resolv.conf`, and drops you in with one command. `exit` when done and it unmounts cleanly.

## 08 · Initramfs · the encryption hook
*`mkinitcpio` with the systemd init and `sd-encrypt`; this is where LUKS unlock is wired*

Edit `/etc/mkinitcpio.conf`:

```bash
# HOOKS: the systemd-based set with sd-encrypt between block and filesystems
sed -i 's/^HOOKS=.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf

# MODULES: name btrfs explicitly so the fallback initramfs can always mount root
sed -i 's/^MODULES=.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf

grep -E '^(HOOKS|MODULES)=' /etc/mkinitcpio.conf   # read it back before building
```

> [!warning] `sd-encrypt` requires the `systemd` hook, not `udev`
> The default Arch `HOOKS` line starts `base udev …` with the busybox init and the `encrypt` hook. `sd-encrypt` only works under the systemd init, so `udev` becomes `systemd` and `keymap consolefont` becomes `sd-vconsole`. Getting this half-right (leaving `udev` in, or keeping `encrypt`) produces an initramfs that cannot unlock the disk and drops you to an emergency prompt with no keyboard map.

> [!note] The `microcode` hook replaces a separate `initrd` line
> Current `mkinitcpio` ships a `microcode` hook that folds `intel-ucode` into the initramfs. With it in `HOOKS` you do **not** add `initrd /intel-ucode.img` to the loader entries in Step 09. If you prefer the older explicit style, drop the `microcode` hook and add the `initrd` line instead. Either way, keep the `intel-ucode` package installed.

*build all initramfs images*
```bash
mkinitcpio -P
# -P builds every preset: linux, linux-lts, and both fallback images
ls -l /boot/initramfs-linux*.img /boot/vmlinuz-linux*
```

> [!warning] On the workforce build: only two of the four images were built
> After `mkinitcpio -P` the first pass had `/boot/initramfs-linux.img` and `/boot/initramfs-linux-lts.img` but **not** the two `-fallback.img` files, because both `/etc/mkinitcpio.d/*.preset` files had been trimmed to `PRESETS=('default')` with the `fallback_image` and `fallback_options` lines commented. The two fallback loader entries in Step 09 then pointed at files that did not exist. Fix: set `PRESETS=('default' 'fallback')` and uncomment `fallback_image=` and `fallback_options="-S autodetect"` in both preset files, then `mkinitcpio -P` again. Confirm four images before rebooting:
> ```bash
> ls /boot/initramfs-linux.img /boot/initramfs-linux-fallback.img /boot/initramfs-linux-lts.img /boot/initramfs-linux-lts-fallback.img
> ```

> [!note] No `/etc/crypttab` entry for root
> Root is unlocked from the initramfs via `sd-encrypt` plus the `rd.luks.name=` cmdline in Step 09. `/etc/crypttab` is only for additional encrypted volumes unlocked *after* boot, of which this machine has none. If you would rather keep the mapping out of the cmdline, write `/etc/crypttab.initramfs` instead (`cryptroot UUID=<container-uuid> none luks,discard`) and rebuild; `sd-encrypt` reads it and the cmdline only needs `root=` and `rootflags=`.

## 09 · systemd-boot · bootloader and loader entries
*install the bootloader, then hand-write four entries*

```bash
bootctl install
systemctl enable systemd-boot-update.service    # auto-updates the EFI binary on systemd upgrades
```

> [!warning] Arch does not auto-generate systemd-boot loader entries
> On Debian the kernel package's hook writes and updates loader entries. Arch has no such hook for systemd-boot out of the box. The clean, low-magic choice is to write the entries once by hand: the image filenames (`vmlinuz-linux`, `initramfs-linux.img`) are stable across kernel updates, so `mkinitcpio` regenerates the images in place and the entries keep working untouched. The alternative, `pacman-hook-kernel-install` (AUR) driving `kernel-install`, generates BLS entries automatically but conflicts with the `mkinitcpio` pacman hooks and needs them masked. Not worth it here.

*get the LUKS container UUID*
```bash
blkid -s UUID -o value /dev/nvme0n1p2       # copy this value
```

*write `/boot/loader/loader.conf`*
```bash
cat > /boot/loader/loader.conf <<'EOF'
default  arch.conf
timeout  3
console-mode keep
editor   no
EOF
```

> [!note] `editor no` matters on an encrypted machine
> With `editor yes` (the default), anyone at the boot menu can press `e` and append `init=/bin/bash` to get a root shell. On an unencrypted machine that is already game over; here the disk is still locked at that point, so it is a smaller hole, but there is no reason to leave it open. Recovery uses the fallback entry or a live USB.

*write `/boot/loader/entries/arch.conf`* (replace `CONTAINER_UUID`)
```
title    Arch Linux
linux    /vmlinuz-linux
initrd   /initramfs-linux.img
options  rd.luks.name=CONTAINER_UUID=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rd.luks.options=discard rw quiet
```

*`/boot/loader/entries/arch-fallback.conf`*
```
title    Arch Linux (fallback initramfs)
linux    /vmlinuz-linux
initrd   /initramfs-linux-fallback.img
options  rd.luks.name=CONTAINER_UUID=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rd.luks.options=discard rw
```

*`/boot/loader/entries/arch-lts.conf`*
```
title    Arch Linux (LTS)
linux    /vmlinuz-linux-lts
initrd   /initramfs-linux-lts.img
options  rd.luks.name=CONTAINER_UUID=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rd.luks.options=discard rw quiet
```

*`/boot/loader/entries/arch-lts-fallback.conf`*
```
title    Arch Linux (LTS, fallback initramfs)
linux    /vmlinuz-linux-lts
initrd   /initramfs-linux-lts-fallback.img
options  rd.luks.name=CONTAINER_UUID=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rd.luks.options=discard rw
```

```bash
bootctl list        # all four entries must appear, arch.conf as default
```

> [!warning] On the workforce build: three loader entries had a stray first line
> `arch-fallback.conf`, `arch-lts.conf`, and `arch-lts-fallback.conf` were each written with the bare container UUID on line 1 and a blank line 2, above `title` (a copy-paste artifact). `bootctl list` flagged each with `Field '<uuid>' without value, ignoring line`. The entries still booted because the rest parsed, but the fix is to delete the first two lines of each. Only `arch.conf` was clean. After editing, `bootctl list` must print no warnings.

> [!note] `rd.luks.options=discard` is a small, deliberate tradeoff
> It passes SSD TRIM through the encrypted mapping. That marginally weakens the encryption (an attacker with repeated disk images can see which blocks are unused) in exchange for sustained SSD write performance and endurance. Standard practice on a laptop; drop it if the machine holds data where that leak matters. Pair it with `systemctl enable fstrim.timer` after reboot rather than continuous discard.

> [!warning] `linux-lts` is the recovery path, and it needs its own working entry
> The reason both kernels are installed: a `linux` update that breaks a driver (Intel WiFi, the GPU, the NVMe) can leave the machine unbootable on a rolling distro. Booting the LTS entry gets you back to a shell to downgrade or wait out the fix. Test the LTS entry actually boots on the first reboot, not the day you need it.

## 10 · Users · sudo · network
*create the user, wire sudo, enable the units*

```bash
passwd                              # root password

useradd -m -c "Naeem Arshad" -G wheel,audio,video,storage -s /bin/zsh naeem
passwd naeem

# passwordless sudo for the primary user (personal laptop, see the note below)
echo 'naeem ALL = NOPASSWD: ALL' > /etc/sudoers.d/naeem
chmod 440 /etc/sudoers.d/naeem
visudo -c                           # syntax check: must end with "/etc/sudoers.d/naeem: parsed OK"

systemctl enable NetworkManager sshd systemd-timesyncd
systemctl is-enabled NetworkManager sshd systemd-timesyncd   # expect three 'enabled' lines
```

> [!note] Contrasts with Rev 4 Step 08
> The sudo group is `wheel`, not `sudo`. The SSH unit is `sshd.service`, not `ssh.service`. `systemd-timesyncd` is part of `systemd` on Arch, so there is no separate package to install, but it still has to be enabled. The `docker` and `libvirt` groups do not exist yet; they are created by those packages in Steps 24 and 25, and `naeem` is added to them there, followed by a re-login. Final group set: `wheel audio video storage docker libvirt`.

> [!note] Passwordless sudo is deliberate on this machine
> This is Naeem's personal laptop and the remote-finish workflow (SSH in, run the rest in `tmux`) is much smoother without a password prompt on every `sudo`. The tradeoff is real and accepted: anyone with an unlocked session has passwordless root. The stock alternative is to skip the drop-in and `visudo` to uncomment `%wheel ALL=(ALL:ALL) ALL` for password sudo instead. `chmod 440` and `visudo -c` are not optional: a syntactically broken file in `/etc/sudoers.d/` disables `sudo` entirely, and on a passwordless setup with no root password that is a lockout.

## 11 · Mirrors & pacman.conf
*persistent mirror ranking and quality-of-life*

```bash
pacman -S reflector

cat > /etc/xdg/reflector/reflector.conf <<'EOF'
--country Germany
--protocol https
--age 12
--latest 10
--sort rate
--save /etc/pacman.d/mirrorlist
EOF

systemctl enable reflector.timer     # weekly refresh
```

Edit `/etc/pacman.conf`: uncomment `Color`, set `ParallelDownloads = 10`, uncomment `VerbosePkgLists`.

> [!note] `multilib` stays disabled
> Rev 4 never enabled i386 multiarch. Leave the `[multilib]` section commented unless something later needs 32-bit libraries (Steam, some Wine setups). Enabling it is a two-line uncomment plus `pacman -Syu` if that day comes.

## 12 · zram
*compressed RAM swap, no disk swap, no hibernation*

```bash
pacman -S zram-generator

cat > /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
EOF
```

Takes effect on the next boot. To start it now without rebooting: `systemctl daemon-reload && systemctl start systemd-zram-setup@zram0.service`, then check with `zramctl` and `swapon --show`.

> [!note] Optional zram-friendly sysctl tuning
> The Arch Wiki suggests, for a zram-only setup, `/etc/sysctl.d/99-vm-zram.conf` with `vm.swappiness=180`, `vm.watermark_boost_factor=0`, `vm.watermark_scale_factor=125`, `vm.page-cluster=0`. These bias the kernel toward using zram early (cheap) instead of reclaiming file cache. Skip it if the machine feels fine at defaults. Not applied on the workforce build.

> [!note] On the workforce build
> `zram-size = min(ram / 2, 8192)` resolved to an 8 GiB device (16 GiB RAM, capped by the `8192` MiB ceiling). `swapon --show` and `zramctl` confirmed `/dev/zram0` active as swap at priority 100.

## 13 · First reboot
```bash
exit                                 # leave the chroot
umount -R /mnt
swapoff -a 2>/dev/null || true
cryptsetup close cryptroot
reboot
```

At the systemd-boot menu you get the four entries. Boot `Arch Linux`, enter the LUKS passphrase when prompted, log in as `naeem`.

*Then: start `tmux`, SSH in from your desk, and run the rest remotely.*

```bash
# on the running machine, before anything else
sudo pacman -Syu                     # read archlinux.org/news first if it is not a fresh ISO day
sudo systemctl enable --now fstrim.timer

# informant: an Arch News reader + pacman hook that blocks -Syu until the news is read
sudo pacman -S informant
sudo informant read                  # clear the backlog once, or the next -Syu aborts

# sanity: confirm the LTS entry boots too, at least once, before you rely on it
```

> [!note] `informant` changes how upgrades feel
> After this, every `pacman -Syu` with unread news aborts in a `PreTransaction` hook until `informant read`. That is the point: it enforces the "read the news first" rule from Step 00 instead of leaving it to habit. `informant` is in `extra`. The `arch-update` tooling in Step 21 sits on top of this, not instead of it: it still runs `pacman -Syu` and still hits this gate.

---

## 14 · paru & the AUR lane
*the audited lane: build recipes, not binaries*

```bash
sudo pacman -S --needed base-devel git rust

git clone https://aur.archlinux.org/paru.git ~/paru
cd ~/paru
makepkg -si
cd .. && rm -rf ~/paru
paru --version
```

> [!note] `paru` vs `paru-bin`
> `paru` builds from source and pulls in the Rust toolchain (~1.5 GB). `paru-bin` is a prebuilt binary that only needs `base-devel git`. This runbook uses `paru` because the choice was to keep the AUR lane fully source-based; switch the clone URL to `paru-bin` if the toolchain size is not worth it.

> [!warning] The AUR trust model: you are the reviewer
> The AUR hosts **build scripts submitted by users**, not vetted packages and not (except `-bin` packages) binaries. Arch does not review them. The discipline, the same shape as Rev 4's "keep the vendor-repo list short and audited":
> - **Read the `PKGBUILD` and any `.install` file every time paru shows the diff**, on first install *and on every update*. A package can change hands and turn hostile in a single update. `paru` shows this by default; do not muscle-memory past it.
> - **Prefer official repos.** Before adding an AUR package, `pacman -Ss` it: things graduate from AUR to `extra` regularly (`ghostty` and `k9s` did). When one does, `paru -Rns` the AUR version and install the repo one.
> - **Prefer packages with a real maintainer, many votes, and recent activity.** A stale package with an open flag for "out of date" is a liability.
> - **Prefer tagged over `-git`.** `-git` packages build from upstream HEAD: more churn, more breakage, useful only when you deliberately want to track development.
> - **Know what you have.** `paru -Qm` lists every foreign (AUR) package. Keep that list short enough to eyeball. After a large `pacman -Syu`, an AUR package built against an old library ABI can break silently until rebuilt: `paru -Sua` rebuilds them.

> [!note] This machine's AUR set
> `paru -Qm` on the workforce build: `noctalia-greeter`, `bibata-cursor-theme` (+ its `python-clickgen` dep), `kubecolor`, `claude-desktop`, `zen-browser-bin`, `ttf-amiri`, `gnome-shell-extension-gsconnect`, `seafile-client`, `k0sctl`, `arch-update` (Step 21), and `paru` itself. Everything else in this runbook comes from official repos, including `awww`, `kubie`, `zed`, `mise`, `sops`, `k9s`, `adw-gtk-theme`, `informant`, all of which were outside apt on Rev 4. Confirm with `pacman -Ss` / `paru -Ss` on the day; things graduate from AUR to `extra` regularly.

## 15 · Minimal GNOME
*the fallback desktop, kept installed for the life of the machine*

```bash
sudo pacman -S gnome-shell gdm nautilus gnome-console gnome-control-center \
               xdg-user-dirs-gtk
sudo systemctl enable gdm
```

> [!note] GNOME metapackage tiers on Arch
> Arch has no curated `gnome-core`. `gnome-shell` is the shell alone; the `gnome` group is the full environment (~60 packages including games and extras). This step takes the middle path: `gnome-shell` plus the handful of pieces that make it a usable session (a file manager, a terminal, settings, and `xdg-user-dirs-gtk` so `~/Downloads` etc. get created). Add more from `pacman -Sg gnome` deliberately if something is missing.

> [!note] gdm is temporary
> Step 22 installs `noctalia-greeter`, which runs under `greetd`. After that, `greetd` becomes `display-manager.service` and gdm is disabled. gdm stays installed as the fallback: `sudo systemctl disable greetd && sudo systemctl enable gdm && reboot` swaps back if the graphical greeter breaks. For the GNOME-only phase, gdm is correct.

## 16 · GNOME add-ons
*keyring, portal, phone integration*

```bash
sudo pacman -S gnome-keyring xdg-desktop-portal-gnome kdeconnect
paru -S gnome-shell-extension-gsconnect
```

> [!note] KDE Connect
> `kdeconnect` (`extra`) is the daemon and works outside Plasma; the niri autostart already spawns `kdeconnectd` and `kdeconnect-indicator`, so installing it here means it works in the niri session from Step 22 on. `gnome-shell-extension-gsconnect` (AUR) is only the GNOME Shell tray integration, so it does nothing under niri and only matters in the GNOME fallback session. The firewall needs TCP+UDP `1714-1764` open for either.

## 17 · Desktop essentials
*audio, power, portals, fonts*

```bash
sudo pacman -S \
  pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
  power-profiles-daemon \
  bluez bluez-utils \
  noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols

paru -S ttf-amiri                   # Arabic; the Arch AUR name, not Debian's ttf-hosny-amiri

sudo systemctl enable power-profiles-daemon bluetooth
systemctl --user enable --now pipewire pipewire-pulse wireplumber
fc-cache -fr
```

> [!warning] `pipewire-jack` conflicts with `jack2`
> `pipewire-jack` and `jack2` both provide `jack`. pacman will ask which to keep; answer `pipewire-jack` (`y` to replace) so PipeWire owns the JACK API. On the workforce build this prompt appeared and `pipewire-jack` was the right choice.

> [!success] Nerd fonts are packaged
> Rev 4 had to `apt-cache search` for a Nerd symbols font and note it "may need manual install". Arch has `ttf-jetbrains-mono-nerd` and `ttf-nerd-fonts-symbols` in `extra`. The Amiri Arabic font is not in the official repos under any name; Debian's `ttf-hosny-amiri` maps to `ttf-amiri` on the AUR.

## 18 · Theming
*the light theme the niri session expects, without a source build*

```bash
sudo pacman -S qt6ct adw-gtk-theme        # verify: 'adw-gtk-theme' vs 'adw-gtk3'
paru -S bibata-cursor-theme               # AUR; a '-bin' variant usually also exists
```

> [!success] No `dart-sass`, no `meson`, no per-user theme build
> Rev 4 built `adw-gtk3` from source because Debian had neither it nor a modern `dart-sass`. Arch ships the built theme in `extra`. This whole sub-step collapses to one `pacman` line plus the cursor theme from AUR.

> [!warning] Installing the theme is not enough: gsettings must point at it
> Exactly as on Debian. `environment.kdl` in the `niri` stow package exports `GTK_THEME`, `QT_QPA_PLATFORMTHEME`, and `XCURSOR_THEME` to niri children, but gsettings-reading UI and the cursor ignore env vars. Set the dconf keys by hand, per-user, and re-run them on any rebuild (they are not dotfiles and `stow` does not restore them):
> ```bash
> gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
> gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
> gsettings set org.gnome.desktop.interface cursor-size 24
> gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
> ```

> [!warning] `environment.kdl` exports these names whether or not the packages exist
> niri sets them for every child with no warning; missing themes just fall back to Adwaita silently. Verify with `ls /usr/share/themes /usr/share/icons` and `command -v qt6ct` rather than trusting the config is doing anything.

## 19 · Snapper & rolling maintenance
*rollback net + the weekly upgrade pass*

> [!danger] This step failed on both the Debian build and the first Arch pass. Verify it, do not assume it.
> On the Debian machine `create-config` was run, appeared to work, and months later there was no config, no `/etc/snapper/configs/root`, and an empty `/.snapshots`. On the first Arch pass `create-config` failed outright with `creating btrfs subvolume .snapshots failed since it already exists` followed by `ERROR: Not a Btrfs subvolume: Invalid argument`, because `@snapshots` was still mounted at `/.snapshots` from fstab when `create-config` tried to create its own subvolume there. The `umount` + `rmdir` before `create-config` and the `mkdir` + `mount` after are what make it work: `create-config` needs an empty, non-existent `/.snapshots` to create its throwaway subvolume, which is then deleted and replaced by the real `@snapshots` mount. Run the verification below and do not move on until it prints a `root` config and a test snapshot.

```bash
sudo pacman -S snapper snap-pac

sudo umount /.snapshots
sudo rmdir /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount /.snapshots
sudo chmod 750 /.snapshots
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
```

*Verify before moving on. All three must pass:*
```bash
sudo snapper list-configs                              # must list a 'root' config
test -f /etc/snapper/configs/root && echo "config OK" || echo "FAILED"
sudo snapper -c root create -d "verify" && sudo snapper -c root list   # snapshot must appear
```

> [!note] `snap-pac` is the Arch equivalent of Debian's apt hook
> `snap-pac` drops a pacman hook that takes a pre/post snapshot pair around every `pacman` transaction, guarded so it does nothing when the `root` config is missing (which is exactly why a missing config fails silently). Once `create-config` genuinely succeeds, `snap-pac` starts working with no further action. Do not hand-roll a `PreTransaction` hook to replace it.

**Weekly:**
```bash
# read archlinux.org/news first
sudo snapper -c root create -d "pre-update $(date +%F)"
sudo pacman -Syu
paru -Sua                                              # rebuild AUR packages
paru -c                                                # clean orphaned AUR deps
sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || true   # remove orphans
```

> [!danger] Rollback is manual with systemd-boot
> The tradeoff of systemd-boot over GRUB + grub-btrfs: no auto-generated "boot into snapshot" menu entries. Recover from a live USB: unlock the disk (`cryptsetup open /dev/nvme0n1p2 cryptroot`), mount the btrfs top level (`mount /dev/mapper/cryptroot /mnt`), `mv /mnt/@ /mnt/@broken`, `btrfs subvolume snapshot /mnt/@snapshots/<N>/snapshot /mnt/@`, reboot. `@home` and `@snapshots` sit outside `@` and survive the swap.

## 20 · Zen browser
*from the AUR, no Flatpak*

```bash
paru -S zen-browser-bin
```

> [!success] Rev 4's Flatpak lane is gone
> Rev 4 installed a system-wide Flatpak solely for the Zen browser, then had to reason about `/var/lib/flatpak` surviving an `@` rollback as an orphan. On Arch, `zen-browser-bin` is in the AUR and installs into the normal package set, so there is no Flatpak, no Flathub remote, and no third lane. `xdg-desktop-portal-gnome` from Step 16 still gives GTK and portal apps native file dialogs and is the portal the niri autostart restarts for screencasting; it does not need Flatpak.

> [!note] If you later want a sandboxed app
> Nothing here blocks adding Flatpak back for a specific app (`sudo pacman -S flatpak && sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo`). It is just not part of the base build any more.

## 21 · Dotfiles & tooling
*pacman lane, then stow*

```bash
sudo pacman -S stow tmux neovim ghostty mise fzf eza bat btop

# dotfiles
git clone git@github.com:naimarshad/dotfiles ~/dotfiles
cd ~/dotfiles
git switch machine/workforce
git config --local user.name  "Naeem Arshad"
git config --local user.email "naimarshad@gmail.com"

rm -rf ~/.config/niri ~/.config/btop ~/.config/arch-update   # let stow own them
stow ghostty zsh niri nvim tmux btop arch-update
# k9s is stowed in Step 24, after its binary is in

# update tooling: arch-update (AUR) is the notifier + updater + post-update cleanup
paru -S arch-update libnotify
systemctl --user enable --now arch-update-tray.service
```

> [!note] `arch-update` update tooling (added 2026-09-09, after the initial build)
> `arch-update` (AUR, by Antiz) is the CachyOS-style update path: an interactive `arch-update` run that shows Arch news, runs `pacman -Syu` then `paru`, then a maintenance pass (orphan removal, `paccache` cache trim, `.pacnew`/`.pacsave` review, pending-reboot and service-restart checks). `arch-update --check` prints the pending count for scripts.
> - The `arch-update` stow package carries `~/.config/arch-update/arch-update.conf`: `NoFlatpak`, `NoALHPCheck`, `AURHelper=paru`, `PrivilegeElevationCommand=sudo`, `KeepOldPackages=2`, `DiffProg=nvim -d`. Because the path is a stow symlink, `arch-update --edit-config` edits the repo file.
> - `DiffProg` is `nvim -d`, not `nvimdiff`: `arch-update` runs `command -v` on the first word only, and Arch's `neovim` package ships no `nvimdiff` symlink (that comes with the `vim` package). `nvim -d` passes the check and is exported to `pacdiff` as `DIFFPROG`.
> - Enable **either** `arch-update-tray.service` **or** `arch-update.timer`, never both: each runs its own periodic check and you would get doubled notifications. The tray is chosen here because Noctalia 5's bar already hosts a `tray` widget; the icon shows there with a count, click to update.
> - `informant` (Step 13) stays as the pacman-level hard gate. `arch-update` calls `pacman -Syu`, so the `informant` `PreTransaction` hook still blocks until `informant read`; `arch-update`'s own news display is on top of that, not a replacement.
> - Passwordless `sudo` (Step 10) means the tray's update runs never prompt.

> [!success] `ghostty` and `mise` are in the repos now
> Rev 4 installed `ghostty` via the `ghostty-ubuntu` community installer (a `curl | sh` that dropped a `.deb`, no auto-update) and `mise` via `curl https://mise.run | sh` into `~/.local/bin`. Both are `pacman -S` on Arch. `mise` from the repo lands at `/usr/bin/mise`; `~/.zshrc` still activates it with `eval "$(mise activate zsh)"`.

> [!warning] The stow set is smaller than the branch package list
> `machine/workforce` carries `arch-update btop fish ghostty hypr k9s niri noctalia nvim starship tmux zsh`. Stow `ghostty zsh niri nvim tmux btop arch-update` here, then `k9s` in Step 24. `hypr` targets Hyprland (unused, the compositor is niri), `fish` is unused (shell is zsh), `starship` is abandoned (prompt is Powerlevel10k, Step 23), `noctalia` is not a stow package (Step 22, it is SOPS-encrypted).

> [!danger] The `niri` config was copied from another machine and carries its assumptions
> Same warning as Rev 4 Step 15. `machine/workforce`'s `niri` package was `cp`'d from `machine/ri-t-0931`, not merged, and it silently inherited that machine's hardware and software versions:
> 1. **Hardware:** `outputs.kdl` may describe the wrong panel (resolution, VRR, scale, position). This T490 panel is 1920x1080, no VRR, single output. niri falls back to preferred mode without complaining. Fix by reading `niri msg outputs` and writing exactly what it reports; drop `position` entirely for a single output. Keep `QT_FONT_DPI` in `environment.kdl` in step with the scale (96 x 1.25 = 120).
> 2. **niri version:** action names drift between releases and a failed `spawn` bind is invisible (the key just does nothing). Arch `niri` is 26.04, the same release the Debian machine built from source, so the audit done there should hold, but re-check every action against `niri msg action --help`.
> 3. **Noctalia version:** the IPC surface. See Step 22.
> `niri validate` passes on all of these because they are runtime lookups, not syntax. Audit against the local hardware and installed versions before trusting the config.

> [!note] Keep `AGENTS.md` and the repo-root `CLAUDE.md` current
> Both were rewritten for this Arch build on 2026-09-06 (pacman/AUR, `linux` + `linux-lts`, LUKS2, systemd-boot manual entries, no Flatpak). Re-check them against reality on the next rebuild rather than trusting them blindly.

## 22 · niri + Noctalia
*the daily driver: both from `extra`, the greeter from AUR*

> [!success] This is where the Arch move pays off
> Rev 4's Step 17 is ~220 lines: a Noctalia apt repo (keyring, deb822 sources, `Signed-By`), niri build dependencies, a Rust toolchain via rustup, `cargo build --release`, copying the binary and five `resources/` files into `/usr/local`, then an awww source build. On the workforce build that was:
> ```bash
> sudo pacman -S niri noctalia awww     # all three in extra: niri 26.04, noctalia 5.0.1, awww 0.12.1
> sudo pacman -S dbus greetd            # greeter dependencies
> paru -S noctalia-greeter              # 1.3.1, the one AUR package here
> ```
> Steps 17b, 17c, 17d, 17e of Rev 4 do not exist here. Version bumps are `pacman -Syu`, with no `cp` dance and no `resources/` re-copy.

### 22a · niri session

`niri` from `extra` installs the session file (`/usr/share/wayland-sessions/niri.desktop`), the portal config, and the `niri.service` user unit. Pick "niri" at the greeter; there is nothing to copy.

```bash
niri --version                        # expect 26.04 or newer
niri validate                         # syntax check of the stowed config (not runtime lookups)
```

> [!note] `niri-session` still does the screencast wiring
> The session wrapper registers `org.gnome.Mutter.ScreenCast` on the bus so `xdg-desktop-portal-gnome` can do window and monitor capture. `autostart.kdl` restarts the portal once the session env is exported. Launching bare `niri` skips this and browsers loop the screen-share dialog.

### 22b · Noctalia shell

```bash
sudo pacman -S noctalia
```

Launch is `spawn-at-startup "noctalia"` in `~/.config/niri/autostart.kdl` (already in the stowed config). The IPC is `noctalia msg <verb>`, unchanged from the Debian machine's Noctalia 5.

> [!warning] Noctalia 5 IPC, and the v4 packaging that still floats around
> The stowed `binds.kdl` and the `swayidle` line in `autostart.kdl` use `noctalia msg` (migrated from v4's `qs -c noctalia-shell ipc call` on this branch already). If `pacman -S noctalia` gives you a v5 build, that all carries over. Some third-party guides and the legacy AUR `noctalia-qs` / `noctalia-shell` packages are **v4** (quickshell-based, `qs -c noctalia-shell ipc call`); do not install those. Verify with `noctalia msg --help` on the installed version. The v5 control-center tabs (from the binary's string table) are `home audio bluetooth calendar media monitor network notifications power system weather`; standalone panels are `launcher clipboard session wallpaper`. The `/emo` launcher context is the one token worth eyeballing after a rebuild.

### 22c · Noctalia greeter

```bash
paru -S noctalia-greeter               # or noctalia-greeter-git to track main
sudo pacman -S greetd dbus

command -v noctalia-greeter-session     # usually /usr/bin/noctalia-greeter-session

sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "/usr/bin/noctalia-greeter-session -- --session niri"
user = "greeter"
EOF

sudo systemctl disable gdm
sudo systemctl enable greetd
```

> [!warning] On the workforce build: greetd crash-looped without a `[terminal]` section
> The first `config.toml` had only `[default_session]`. `greetd` failed on every start with `no terminal specified`, hit the systemd start-limit, and left the machine with no greeter (recover by logging in on a VT and adding the section). `greetd` needs `[terminal]` with `vt = 1`. The `-- --session niri` argument tells `noctalia-greeter-session` which Wayland session to launch after authentication.

> [!note] The greeter is the one genuine AUR package here
> `noctalia-greeter` is not in `extra`; the Noctalia docs point to the AUR (`noctalia-greeter` stable, `noctalia-greeter-git` for development). It needs `greetd` and D-Bus running on this machine. After enabling `greetd`, `display-manager.service` resolves to it. To fall back to GNOME's login screen: `sudo systemctl disable greetd && sudo systemctl enable gdm && reboot`. The greeter's own optional config is `greeter.toml` (see the Noctalia greeter configuration docs).

### 22d · awww wallpaper daemon

```bash
sudo pacman -S awww        # if absent:  paru -S awww
awww --version
```

> [!note] awww, not swww
> `autostart.kdl` spawns `awww-daemon` and `wallpaper.sh` drives it (`awww query`, `awww img … --transition-type fade`). `awww` is LGFae's maintained fork of the archived `swww`. `swww` *is* in `extra`; do not "fall back" to it, the config calls the `awww` binaries. If only `swww` is available, `awww` is on the AUR. It runs under niri (which implements `wlr-layer-shell`) and not under GNOME, which is fine: the wallpaper is a niri-session concern.

### 22e · Glass effect needs a wallpaper underneath

Noctalia panel glass and niri window blur both read the **wallpaper layer**, not the windows behind. With no wallpaper set they frost solid black, which looks flat rather than frosted.

```bash
mkdir -p ~/.config/secrets
echo "YOUR_UNSPLASH_ACCESS_KEY" > ~/.config/secrets/unsplash-key
chmod 600 ~/.config/secrets/unsplash-key

bash ~/.config/niri/wallpaper.sh &
awww query        # must show an image path, not 'color: 000000'
```

> [!danger] The Unsplash key path must stay outside the stowed tree
> `~/.config/niri` is a stow symlink into the dotfiles repo. `wallpaper.sh` reads `~/.config/secrets/unsplash-key` (outside the stowed tree) and `.gitignore` carries `**/unsplash-key` as a backstop. If a future edit repoints it inside `~/.config/niri/`, the key is one `git add -A` from being published. The settings that matter, all correct once a wallpaper exists: `[backdrop] enabled = true` and `[shell.panel] transparency_mode = "glass"` in Noctalia settings, and `background-effect { xray true; blur true; noise 0.15; saturation 1.4 }` in `rules.kdl` (needs niri 26.04+). `xray true` is the key line: it blurs the wallpaper, not the windows.

### 22f · Noctalia config lives outside `~/.config` and is SOPS-encrypted

> [!danger] Noctalia 5 config path, and why it is not stowed
> v5 keeps its config at `~/.local/state/noctalia/settings.toml` (v4 used `~/.config/noctalia`). It holds theme, panel transparency, bar layout, lockscreen widgets, the `[plugins] enabled` list, and `plugin_settings.<id>` tables. Those plugin tables hold **plaintext credentials** (`api_key`, `api_secret`, `kubeconfig` for the opnsense / syncthing / k8s-status plugins). This repo is public. The file is tracked encrypted with SOPS, not stowed.

```bash
sudo pacman -S sops age              # verify 'sops': repo or AUR

# one-time: age key that ~/.zshrc points SOPS_AGE_KEY_FILE at
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
# put the printed public key in .sops.yaml under creation_rules

# restore on a rebuild
mkdir -p ~/.local/state/noctalia
sops --decrypt noctalia/settings.sops.toml > ~/.local/state/noctalia/settings.toml
noctalia msg config-reload
```

> [!warning] Back the age private key up off-repo
> `~/.config/sops/age/keys.txt` is the only way to read `noctalia/settings.sops.toml`. Mode 600, outside the repo, and if it is lost the encrypted config is unrecoverable. `.gitignore` also carries `noctalia/settings.toml` so a stray decrypt cannot be committed. SOPS has no TOML parser, so it encrypts the whole file as one opaque blob: it round-trips, but git diffs on it are not readable. Acceptable for a GUI-edited settings file. Plugin credentials are entered through the GUI (`noctalia msg settings-open-plugin <author/plugin>`), never through a shell.

---

## 23 · Shell environment
*zsh framework, prompt, plugins, version manager*

`zsh` was installed in Step 05 and set as `naeem`'s shell in Step 10. This is everything `~/.zshrc` sits on.

```bash
# oh-my-zsh (unattended)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# custom plugins ~/.zshrc loads by name
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/you-should-use"
git clone https://github.com/fdellwing/zsh-bat.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-bat"

# from the repos: syntax highlighting, and the kubectl wrappers ~/.zshrc expects
sudo pacman -S zsh-syntax-highlighting kubie          # kubie is in extra (0.28 on the workforce build)
paru -S kubecolor                                     # kubecolor was AUR on the workforce build
```

> [!note] Loose ends carried from Rev 4
> `zsh-history-substring-search` and `zsh-completions` are referenced in `~/.zshrc` but not cloned; both are packages (`zsh-history-substring-search` in `extra`). Neither breaks the shell. `fzf eza bat` came in Step 21. `starship` stays uninstalled and unstowed (the prompt is p10k).

## 24 · Containers & Kubernetes tooling

```bash
# Docker: the 'docker' package, NOT docker-ce (that is Debian/Ubuntu only)
sudo pacman -S docker docker-buildx docker-compose
sudo usermod -aG docker naeem          # re-login to take effect
sudo systemctl enable --now docker

# kubectl
sudo pacman -S kubectl

# secrets pair (sops installed in Step 22f if you did niri first; otherwise here)
sudo pacman -S age sops

# k9s: in 'extra', no more downloaded .deb
sudo pacman -S k9s
```

> [!success] Almost all of Rev 4 Step 19 is now one `pacman` line each
> Debian needed: `get.docker.com` in `REPO_ONLY` mode to add an apt repo pinned to `trixie` (because Docker does not publish for `forky`), a hand-built `pkgs.k8s.io` keyring and list pinned to `v1.37`, a `sops` release binary into `/usr/local/bin` (not in the archive), and a `k9s` `.deb` from GitHub releases. On Arch all four are in `extra` and roll with `pacman -Syu`. The `k9s` stow package still supplies `~/.config/k9s/` (config, aliases, catppuccin-latte skin), so `stow k9s` after this.

## 25 · Virtualization
*qemu + libvirt for local VMs and Vagrant*

```bash
sudo pacman -S qemu-desktop libvirt virt-manager dnsmasq dmidecode
sudo usermod -aG libvirt naeem         # re-login to take effect
sudo systemctl enable --now libvirtd
```

> [!note] On the workforce build: `dmidecode` was missing at first
> `libvirtd` logged `Cannot find 'dmidecode' in path` twice on every start until it was installed. It is what libvirt uses to read the host's SMBIOS/DMI tables for capability reporting. Not fatal, but it belongs in the package list.

`~/.zshrc` sets `VAGRANT_DEFAULT_PROVIDER=libvirt`, so Vagrant (installed when needed) uses this stack rather than VirtualBox.

## 26 · Editors & desktop apps

```bash
# all in extra: zed, fuzzel (niri launcher), alacritty (fallback terminal), obsidian, fastfetch
sudo pacman -S zed fuzzel alacritty obsidian fastfetch

# Claude Code: upstream installer, into ~/.local/share/claude, symlink in ~/.local/bin
curl -fsSL https://claude.ai/install.sh | bash

# Claude Desktop: AUR
paru -S claude-desktop                                    # verify exact package name
```

> [!note] `fuzzel` is the niri launcher
> niri binds expect `fuzzel`; `alacritty` is a fallback terminal to `ghostty`. Neither matters under GNOME, both matter after Step 22.

> [!note] Claude Code here is just the binary
> The `curl | bash` above installs the CLI and nothing else. The memory extractor, the SessionStart injector, the `~/Obsidian/MEMORY.md` freeze guard, and the per-machine routing config are all Step 28, deliberately after syncthing (Step 27) so the Obsidian vault the extractor writes to actually exists.

## 27 · Sync & networking

```bash
sudo pacman -S syncthing wireguard-tools
paru -S seafile-client
systemctl --user enable --now syncthing
```

> [!note] `autostart.kdl` references these
> `autostart.kdl` spawns `seafile-applet` (from `seafile-client`, AUR) and `kdeconnectd` + `kdeconnect-indicator` (from `kdeconnect`, installed in Step 16). `kdeconnect`'s firewall ports are TCP+UDP `1714-1764`.

## 28 · Claude Code · memory, hooks, and the freeze guard
*the `~/.claude` setup: SessionEnd extractor, SessionStart injector, MEMORY.md protection*

Do this after Step 27. The memory extractor writes into `~/Obsidian/Claude/claude-memory`, and that path only exists once syncthing has pulled `~/Obsidian` down.

The setup has two parts:
1. **Claude Code itself** (the binary, installed in Step 26): `~/.local/share/claude/versions/<ver>`, symlinked from `~/.local/bin/claude`, self-updating.
2. **`~/claude-memory-extractor`**: a git repo (`github.com/naimarshad/claude-memory-extractor`) whose `install.sh` wires three things into `~/.claude/`:
   - **SessionEnd** hook → `python3 ~/.claude/hooks/memory_extractor.py`, distils each finished session into the vault through a headless `claude -p --model haiku` call. Rides on the subscription OAuth, so no `ANTHROPIC_API_KEY`.
   - **SessionStart** hook → `~/.claude/hooks/session-start`, a small Go binary that injects the current project's DosDonts notes into a new session.
   - **`memory-recall`** skill → symlinked into `~/.claude/skills/`.

### 28a · Prerequisites, before `install.sh`

```bash
sudo pacman -S --needed jq python go
sudo pacman -D --asexplicit go jq     # so orphan cleanup cannot remove them
command -v claude jq python3 go        # all four must resolve
```

> [!warning] On the workforce build: `go` was left as an orphan
> `go` came in as a dependency of an AUR build, not an explicit install, so `pacman -Qtdq` listed it as a removable orphan. A later `pacman -Rns $(pacman -Qtdq)` would have removed the Go toolchain and broken the `session-start` rebuild. `pacman -D --asexplicit go jq` marks them as wanted in their own right. Review `pacman -Qtdq` before any orphan purge regardless: most of its entries are AUR makedepends (`meson`, `nasm`, `cbindgen`, `xorg-server-xvfb`) and safe, but eyeball the list.
>
> The `arch-update` tooling (Step 21) runs this same orphan check on **every** update and offers to remove what it finds, so `--asexplicit` on `go` and `jq` is what stops it proposing them each time. Answer its orphan prompt with the same care as a manual `pacman -Qtdq` review.

> [!warning] Install `go` before running `install.sh` or the SessionStart hook is skipped silently
> `install.sh` hard-requires `jq` and `python3` and aborts loudly without them. `go` it treats as optional: if `go` is not on PATH it prints one line to stderr (`go not found, skipping the optional SessionStart hook`) and registers only SessionEnd, exit status still 0. The DosDonts injection is wanted on this machine, so `go` has to be present first. On Arch the `python` package provides `/usr/bin/python3` (a symlink to the current `python3.x`), which is what the hook command in `settings.json` calls.

### 28b · Restore from the `~/.claude` backup

The `~/.claude` backup was taken before the wipe. Restore selectively, not wholesale, because several entries are machine-specific or stale:

```bash
# adjust the source path to wherever the backup actually is
BK=~/backup/claude

cp "$BK/CLAUDE.md"             ~/.claude/CLAUDE.md
cp "$BK/settings.json"         ~/.claude/settings.json
cp "$BK/memory-extractor.json" ~/.claude/memory-extractor.json
cp -r "$BK/projects"           ~/.claude/projects       # native per-project auto-memory (+ transcripts)
```

> [!danger] Do not restore `~/.claude/.memory-unlock`
> That sentinel is what *disables* the `~/Obsidian/MEMORY.md` freeze. Its absence is the safe state; it should exist only for the few minutes Naeem is deliberately editing `MEMORY.md`. If the backup contains it, skip it.

> [!note] What each restored file carries that a fresh `install.sh` would not
> - **`settings.json`**: the `theme: light` / `tui: fullscreen` prefs, *and* the two `PreToolUse` blocks that `deny` writes to `~/Obsidian/MEMORY.md` (one matching `Write|Edit|MultiEdit|NotebookEdit`, one matching `Bash` for shell redirection). `install.sh` merges in the SessionEnd/SessionStart hooks but never adds the freeze guard. Without this restore, `MEMORY.md` is unprotected. (`settings.json.bak` in the backup is the pre-freeze-guard version; do not use it.)
> - **`memory-extractor.json`**: the real routing. `install.sh` writes `config.example.json` verbatim (placeholder `~/path/to/work/repos` route, `machine: "my-laptop"`) and *only if the file is absent*. The workforce values: `default_vault` = `~/Obsidian/Claude/claude-memory`, `routes` = `[]`, `machine` = `"workforce"`, `model` = `"haiku"`. Empty `routes` plus a personal `default_vault` is deliberate: nothing can land in the work vault (`~/Obsidian/RI/`) by accident.
> - **`CLAUDE.md`**: the four `@~/Obsidian/{USER,SOUL,IDENTITY,MEMORY}.md` import lines. `install.sh` only `touch`es this file and manages the vault-check block between its marker comments; it does not add the imports. Those four files arrive with the synced `~/Obsidian` and are themselves frozen to assistants.
> - **`projects/`**: Claude Code's *native* auto-memory, `projects/<slug>/memory/MEMORY.md` plus notes (e.g. `-home-naeem-dotfiles/memory/workforce-machine-stack.md`), which is a different store from the Obsidian extractor vault. Restore it to keep the per-project memory; the session `.jsonl` transcripts alongside it are optional bulk.

`~/.claude/.credentials.json` (OAuth, mode 600) either restores from the backup or is recreated by running `claude` once and doing `/login`.

### 28c · Clone the extractor and run the installer

```bash
git clone https://github.com/naimarshad/claude-memory-extractor.git ~/claude-memory-extractor
cd ~/claude-memory-extractor
./install.sh
```

`install.sh` is idempotent and safe to re-run. It will:
- symlink `~/.claude/hooks/memory_extractor.py` → `~/claude-memory-extractor/memory_extractor.py` (so a `git pull` here updates the live hook)
- `go build` the SessionStart binary into `~/.claude/hooks/session-start`
- symlink `~/.claude/skills/memory-recall` → the repo's copy (removing a stale real directory first)
- merge the SessionEnd and SessionStart registrations into `settings.json` via `jq`, testing for *its own* command strings, so it will not double-register next to the blocks restored in 28b
- write `memory-extractor.json` from the example **only if the file is absent**, so the one restored in 28b is left alone
- rewrite the vault-check block in `~/.claude/CLAUDE.md` between its marker comments

> [!warning] The Python hook is a symlink into `~/claude-memory-extractor`
> `~/.claude/hooks/memory_extractor.py` is a symlink whose target is `~/claude-memory-extractor/memory_extractor.py`. If the backup restored a `hooks/` directory, that symlink dangles until the repo is cloned back to exactly `~/claude-memory-extractor`. Cloning it there and running `install.sh` fixes both the symlink and the Go binary (which should be rebuilt on the new machine even though the arch is the same). Never `cp` the hook in as a real file; the symlink is what makes `git pull` update it.

### 28d · Verify

```bash
# routing resolves to the personal vault (not the work vault, not the bare fallback)
python3 ~/.claude/hooks/memory_extractor.py --resolve-vault "$PWD"
#   -> /home/naeem/Obsidian/Claude/claude-memory

# all three hook types are present
jq '.hooks | keys' ~/.claude/settings.json
#   -> ["PreToolUse","SessionEnd","SessionStart"]

# the MEMORY.md freeze guard is armed (two commands mention MEMORY)
jq -r '.hooks.PreToolUse[].hooks[].command' ~/.claude/settings.json | grep -c MEMORY
#   -> 2

# the Go binary exists and runs
~/.claude/hooks/session-start </dev/null; echo "exit $?"

# global CLAUDE.md has the four imports at the top
head -5 ~/.claude/CLAUDE.md

# routing config is the real one, not the example
cat ~/.claude/memory-extractor.json      # machine: "workforce", routes: []
```

Then start a real `claude` session in `~/dotfiles`, let it end, and check `~/Obsidian/Claude/claude-memory/.extractor.log` for a line from that session. If notes stop appearing later, that log and `~/Obsidian/Claude/claude-memory/.extractor-failed/` are the first place to look: a failed extraction parks its payload there with the exact `--extract` retry command.

> [!note] Try the MEMORY.md freeze once, so you know it works
> In a throwaway session, ask Claude to edit `~/Obsidian/MEMORY.md`. The `PreToolUse` hook must deny it with the "frozen to assistants" message. If the edit goes through, `settings.json` did not restore correctly. Naeem unlocks deliberately with `touch ~/.claude/.memory-unlock` and re-locks by removing it; an assistant cannot create that file.

---

## Restore checklist

- [ ] booted UEFI (`/sys/firmware/efi/fw_platform_size` is `64`) · correct device confirmed with `lsblk` before `sgdisk --zap-all`
- [ ] GPT · 2 GiB ESP (`ef00`, vfat) · partition 2 (`8309`) · ESP formatted · fstab `/boot` line uses `fmask=0077,dmask=0077`
- [ ] `cryptsetup luksFormat --type luks2` on p2 · opened as `cryptroot` · LUKS passphrase recorded somewhere safe
- [ ] btrfs on `/dev/mapper/cryptroot` · `@ @home @log @snapshots` created and mounted · ESP mounted at `/mnt/boot`
- [ ] `pacstrap -K` incl. `linux linux-lts linux-firmware intel-ucode cryptsetup openssh` · `genfstab -U` written and checked
- [ ] timezone / locale / hostname `workforce` / hosts file · `KEYMAP=us` (a valid keymap name) · `systemctl status systemd-vconsole-setup.service` clean after first boot
- [ ] `mkinitcpio.conf` HOOKS has `systemd` + `sd-encrypt` (not `udev` + `encrypt`) · `MODULES=(btrfs)` · presets are `PRESETS=('default' 'fallback')` · `mkinitcpio -P` built **all four** images (`linux`, `linux-fallback`, `linux-lts`, `linux-lts-fallback`)
- [ ] `bootctl install` · `systemd-boot-update.service` enabled · `loader.conf` with `editor no`
- [ ] four loader entries (`arch`, `arch-fallback`, `arch-lts`, `arch-lts-fallback`), each starting at `title` with no stray first line · `bootctl list` shows all four and prints **no** "without value" warnings
- [ ] user in `wheel audio video storage` · `/etc/sudoers.d/naeem` (`naeem ALL = NOPASSWD: ALL`, mode 440, `visudo -c` clean) · `NetworkManager sshd systemd-timesyncd` all `enabled`
- [ ] `reflector.conf` (Germany) + `reflector.timer` enabled · `pacman.conf` Color / ParallelDownloads / VerbosePkgLists
- [ ] `zram-generator.conf` written · `swapon --show` shows `/dev/zram0` after reboot
- [ ] first reboot: LUKS prompt appears · logs in · **LTS entry boots too** · `fstrim.timer` enabled · `informant` installed and `informant read` run once
- [ ] `paru` built · `paru -Qm` list is short and understood
- [ ] `gnome-shell` + `gdm` + add-ons + portal + `kdeconnect` + `gnome-shell-extension-gsconnect` (AUR) + pipewire + `bluez-utils` (`bluetooth` enabled) + fonts + `ttf-amiri` (AUR) · gdm enabled for the GNOME phase
- [ ] theming: `adw-gtk-theme` + `qt6ct` from repo · `bibata-cursor-theme` from AUR · **gsettings `gtk-theme` and `cursor-theme` actually set**
- [ ] snapper: `umount`/`rmdir` before `create-config`, `mkdir`/`mount`/`chmod 750` after · `snapper list-configs` lists `root` · `SNAPPER_CONFIGS="root"` · a test snapshot appears (failed on both Debian and the first Arch pass, verify it) · `snap-pac` installed · timers enabled
- [ ] Zen browser installed from AUR (`zen-browser-bin`) · no Flatpak on the system
- [ ] dotfiles cloned · `machine/workforce` checked out · git identity set `--local` · stray `~/.config/{niri,btop}` cleared · `stow ghostty zsh niri nvim tmux btop arch-update`
- [ ] `arch-update` + `libnotify` from AUR/`extra` · `arch-update --check` runs · `arch-update-tray.service` enabled `--user` (not the timer) · tray icon visible in Noctalia's `tray` widget
- [ ] `niri` + `noctalia` from `extra` · `niri --version` >= 26.04 · `noctalia msg --help` confirms v5 IPC
- [ ] `noctalia-greeter` from AUR · `greetd` + `dbus` · `/etc/greetd/config.toml` has `[terminal] vt = 1` and points at `noctalia-greeter-session -- --session niri` · `greetd` enabled, gdm disabled
- [ ] `outputs.kdl` mode/scale/VRR matched to `niri msg outputs`, `position` dropped · `QT_FONT_DPI` in step with scale
- [ ] `awww` installed (repo or AUR) · a real wallpaper set (`awww query` is not `color: 000000`) · Unsplash key at `~/.config/secrets/`, not under stowed `~/.config/niri/`
- [ ] `noctalia/settings.sops.toml` decrypts to `~/.local/state/noctalia/settings.toml` · age key backed up off-repo · plaintext `settings.toml` gitignored
- [ ] oh-my-zsh + p10k + plugins · `zsh-syntax-highlighting` + `kubie` (extra) + `kubecolor` (AUR) · `starship` skipped
- [ ] `docker` (not docker-ce) + `kubectl` + `k9s` + `age`/`sops` from repos · `docker` / `libvirt` groups added · `stow k9s`
- [ ] `qemu-desktop` + `libvirt` + `virt-manager` · `libvirtd` enabled
- [ ] Zed / Claude Code / Claude Desktop / Obsidian / fuzzel / alacritty
- [ ] syncthing user service · `seafile-client` (AUR) installed · `~/Obsidian` synced all the way down before starting Step 28
- [ ] Step 28: `jq python go` on PATH before `install.sh` · `pacman -D --asexplicit go jq` · `~/.claude/{CLAUDE.md,settings.json,memory-extractor.json,projects}` restored from the backup · `.memory-unlock` **not** restored · `.credentials.json` restored or `/login`
- [ ] Step 28: extractor cloned to exactly `~/claude-memory-extractor` · `install.sh` run · `~/.claude/hooks/memory_extractor.py` symlink resolves · `~/.claude/hooks/session-start` built and runs
- [ ] Step 28 verify: `--resolve-vault "$PWD"` prints `~/Obsidian/Claude/claude-memory` · `settings.json` has `PreToolUse` + `SessionEnd` + `SessionStart` · `memory-extractor.json` says `machine: "workforce"`, `routes: []` · a test edit of `~/Obsidian/MEMORY.md` is **denied**
- [ ] `AGENTS.md` and repo-root `CLAUDE.md` rewritten for Arch and re-checked

---
*Arch Linux (rolling) · GNOME first boot, then niri (`extra`) + Noctalia (`extra`) · greetd + noctalia-greeter · systemd-boot · btrfs/snapper on LUKS2 · zram · no Flatpak · Claude Code memory + hooks restored in Step 28 · Rev 2, verified record*
