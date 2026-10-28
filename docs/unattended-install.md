# Unattended install ISO

Build an online or offline installer ISO from your own `ojuny-template` fork.
The ISO partitions the target disk, copies the flake to
`/home/<user>/repos/nix-flake`, regenerates the hardware module for that machine,
runs `nixos-install --flake`, and leaves the modified flake in the installed
system.

The online live environment needs network access. The target system is
installed from the flake with `nixos-install`, so the flake inputs are fetched
online. Pass `--offline` to build the full-system offline ISO instead. That image
carries the full system runtime closure, and the install service skips the
network check.

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

Build the offline variant:

```sh
nix develop
scripts/make-unattended-iso.sh --offline \
  --flake ~/repos/my-template --disk /dev/disk/by-id/...
```

The offline ISO is larger because it contains the full system. Keep it under
8,000,000,000 bytes so an 8 GB USB can hold it. The script prints the size and
warns above 7.4 GB. You can also check a built image with
`scripts/check-iso-size.sh path/to/image.iso`.

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
   root or a LUKS2-encrypted ext4 root, and an optional swap partition.
4. The flake snapshot is copied to `/mnt/home/<user>/repos/nix-flake`.
5. `regenerate-hardware` writes `modules/07-system/00-hardware.nix` and
   `modules/07-system/facter.json` for the target disk and bootloader.
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

The VM needs 4 GB RAM and accelerated virtio graphics (`virtio-vga-gl` with
`gl=on`).

```sh
qemu-img create -f qcow2 /tmp/ojuny-unattended.qcow2 30G
firmware="$(nix build --no-link --print-out-paths nixpkgs#OVMF.fd)/FV/OVMF.fd"
iso="$(echo result-unattended/*.iso)"

qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 4 -cpu host \
  -bios "$firmware" \
  -device virtio-vga-gl \
  -device virtio-keyboard-pci -device virtio-tablet-pci \
  -drive file="$iso",media=cdrom,readonly=on \
  -drive file=/tmp/ojuny-unattended.qcow2,if=virtio \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -display gtk,gl=on
```

The target disk is `/dev/vda` in this QEMU command. Use
`--disk /dev/vda` when building the test ISO, or use a by-id path that resolves
to `/dev/vda`.

## Limitations

- The online ISO needs network access. Use the offline variant for a
  network-free install.
- The offline ISO is a full-system image and is significantly larger than the
  online image.
- Destructive: the configured disk is wiped without an interactive installer.
- `x86_64-linux` only.
- UEFI and BIOS are supported by separate builds. The firmware setting is fixed
  at ISO build time.
- LUKS2 root encryption is optional through `--encrypt`; the passphrase is
  stored on the live ISO with mode `0600`.
- The ISO installs the flake snapshot it was built from.
- Wi-Fi is not configured by the unattended service. Use a wired connection.
- The installed flake is modified before install. It is the configuration that
  was installed, not a pristine copy of the fork.
