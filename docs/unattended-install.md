# Unattended install ISO

Build an online installer ISO from your own `ojuny-template` fork. The ISO
partitions the target disk, copies the flake to
`/home/<user>/repos/nix-flake`, regenerates the hardware module for that machine,
runs `nixos-install --flake`, and leaves the modified flake in the installed
system.

The live environment needs network access. The target system is installed from
the flake with `nixos-install`, so the flake inputs are fetched online.

## Build

From `ojuny-installer`:

```sh
nix develop
scripts/make-unattended-iso.sh --flake ~/repos/my-template --disk /dev/disk/by-id/...
```

The script prompts for the remaining values. Use `--dry-run` to print the
settings and the build command without building the ISO.

The ISO is copied to `result-unattended/`. Write it to a USB stick or attach it
to a virtual machine.

## Modes

`prepared` mode uses the fork as-is. The installer detects the user and host
from the flake, regenerates only the hardware module, and applies optional
password, SSH key, timezone, locale and keymap overrides when they are set.

`bundled` mode copies the fork and runs `prepare-repo.py` with the installer
settings. This generates the user, host and configuration values even when the
fork has not been prepared yet.

## Install flow

1. The live ISO boots to a console and starts `ojuny-unattended-install`.
2. The service waits for the target disk, checks that it is not mounted, and
   optionally counts down before wiping it.
3. `disko` creates a GPT layout with a BIOS boot partition, an ESP, an ext4
   root, and an optional swap partition.
4. The flake snapshot is copied to `/mnt/home/<user>/repos/nix-flake`.
5. `regenerate-hardware` writes `modules/07-system/00-hardware.nix` for the
   target disk and bootloader.
6. The copy is initialized as a git repository and committed.
7. `nixos-install --flake /mnt/home/<user>/repos/nix-flake#<host>` installs the
   system.
8. `~/.config/nix-settings-gui/config.json` is written and the flake is chowned
   to the target user.
9. The machine reboots or powers off.

On failure the service prints the error and starts a shell on tty1. The target
is not rebooted automatically.

## Settings

The settings are stored in a temporary flake input. They never enter the
repository. The password is hashed with `mkpasswd` before the ISO is built.

- `mode`: `prepared` or `bundled`.
- `disk`: target block device, preferably `/dev/disk/by-id/...`.
- `firmware`: `efi` or `bios`.
- `host`, `username`, `fullName`, `hashedPassword`, `sshKeys`.
- `shell`, `timezone`, `locale`, `keymap`.
- `swapSize`: `0` disables the swap partition.
- `confirmSeconds`: countdown before wiping the disk.
- `finalAction`: `reboot` or `poweroff`.
- `cloneRelative`: path below the home directory, default `repos/nix-flake`.
- `stateVersion`: used by bundled mode.

## Test in QEMU

Build the ISO, create a target disk, and boot the ISO as a CD-ROM. Use a
separate disk for the installation target. The ISO needs user-mode networking.

```sh
qemu-img create -f qcow2 /tmp/ojuny-unattended.qcow2 30G
firmware="$(nix build --no-link --print-out-paths nixpkgs#OVMF.fd)/FV/OVMF.fd"
iso="$(echo result-unattended/*.iso)"

qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 4 -cpu host \
  -bios "$firmware" \
  -device virtio-vga \
  -device virtio-keyboard-pci -device virtio-tablet-pci \
  -drive file="$iso",media=cdrom,readonly=on \
  -drive file=/tmp/ojuny-unattended.qcow2,if=virtio \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -display gtk
```

The target disk is `/dev/vda` in this QEMU command. Use
`--disk /dev/vda` when building the test ISO, or use a by-id path that resolves
to `/dev/vda`.

## Limitations

- Online install only.
- Destructive: the configured disk is wiped without an interactive installer.
- `x86_64-linux` only.
- UEFI and BIOS are supported by separate builds. The firmware setting is fixed
  at ISO build time.
- No LUKS in version 1.
- The ISO installs the flake snapshot it was built from.
- Wi-Fi is not configured by the unattended service. Use a wired connection.
- The installed flake is modified before install. It is the configuration that
  was installed, not a pristine copy of the fork.
