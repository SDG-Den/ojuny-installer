# ojuny-installer

Calamares live ISO and unattended installer ISO for
[ojuny-template](https://github.com/SDG-Den/ojuny-template).

The Calamares ISO boots the Ojuny desktop from `ojuny-desktop`, runs a rebranded
Calamares, partitions and mounts the target, copies the pinned template to
`/home/<user>/repos/nix-flake`, generates the hardware, user and host modules,
and finishes with `nixos-install --flake`.

The unattended ISO boots a minimal console, partitions the target with disko,
copies the template fork to `/home/<user>/repos/nix-flake`, regenerates its
hardware module, and runs `nixos-install --flake` without user interaction.
The modified flake is left in the installed system.

## Requirements

- Calamares ISO install: 10 GB RAM minimum. 12 GB or 16 GB is recommended. The live environment is roughly 8 GB uncompressed, so 8 GB leaves no headroom.
- Unattended ISO install: 10 GB RAM minimum.
- `nix run .#setup` from `ojuny-template`: 8 GB RAM, because it builds the compiled packages from source.
- Network access for all install paths.

## Build

```sh
nix build .#ojuny-iso
```

The image is written to `result/iso/*.iso`.

For development:

```sh
nix develop
nix flake check
```

The template is pinned as a flake input. To build an ISO that installs your own
modified template:

```sh
nix build .#ojuny-iso \
  --override-input ojuny-template path:$HOME/repos/my-template
```

## Unattended ISO

```sh
nix develop
scripts/make-unattended-iso.sh \
  --flake "$HOME/repos/my-template" \
  --disk /dev/disk/by-id/...
```

The script prompts for firmware, account, password and SSH keys. It hashes the
password before building, writes the settings to a temporary flake input, and
copies the ISO to `result-unattended/`. Use `--dry-run` to inspect the settings
and build command without building.

See `docs/unattended-install.md` for modes, the install flow and limitations.

## Test in QEMU

```sh
qemu-img create -f qcow2 /tmp/ojuny-test.qcow2 20G
firmware="$(nix build --no-link --print-out-paths nixpkgs#OVMF.fd)/FV/OVMF.fd"
iso="$(echo result/iso/*.iso)"

qemu-system-x86_64 \
  -enable-kvm -m 16384 -smp 4 -cpu host \
  -bios "$firmware" \
  -device virtio-vga \
  -device virtio-keyboard-pci -device virtio-tablet-pci \
  -drive file="$iso",media=cdrom,readonly=on \
  -drive file=/tmp/ojuny-test.qcow2,if=virtio \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -display gtk
```

The installer needs network access because `nixos-install` fetches the
template's flake inputs.

The Calamares ISO includes the compiled Ojuny GUI packages from the template's
locked nixpkgs. The installed system uses the same template lock, so those store
paths are reused. A prepared repository keeps its own lock and may rebuild them.

## Installed system

- Configuration: `/home/<user>/repos/nix-flake`, initialized as a git repo.
- `modules/07-system/00-hardware.nix` is generated from the target mounts.
- `modules/01-users/01-user.nix` is generated from the Calamares account page.
- `modules/07-system/00-host.nix` registers `nixosConfigurations.<hostname>`
  and points the update GUI at `path:/home/<user>/repos/nix-flake`.
- `system.stateVersion` and `home.stateVersion` are set to the installer's
  release.
- The account password is written as `hashedPassword`; `users.mutableUsers`
  stays `false`, so password changes go through the settings GUI and a rebuild.

## Layout

- `flake.nix`: inputs, dev shell, packages and the ISO outputs.
- `nixos/iso.nix`: live Calamares ISO configuration.
- `nixos/unattended.nix`: unattended installer ISO configuration.
- `nixos/unattended-install.py`: unattended install service.
- `unattended/default-settings.nix`: unattended defaults.
- `scripts/make-unattended-iso.sh`: settings generator and ISO build wrapper.
- `packages/calamares-ojuny.nix`: Calamares wrapper pointing at our extensions.
- `packages/ojuny-calamares-extensions/`: settings, branding and the `ojuny`
  job module that installs the template.

## Limitations

- `x86_64-linux` only.
- UEFI uses systemd-boot; BIOS uses GRUB.
- Encrypted BIOS boot uses a generated GRUB keyfile and GRUB cryptodisk.
- No offline install.
- The unattended ISO wipes the configured disk without an interactive
  installer.
- The unattended ISO does not configure Wi-Fi. Use a wired connection.
