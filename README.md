# ojuny-installer

Calamares live ISO and unattended installer ISO for
[ojuny-template](https://github.com/SDG-Den/ojuny-template).

The Calamares ISO boots the Ojuny desktop from `ojuny-desktop`, runs a rebranded
Calamares, partitions and mounts the target with optional LUKS2 root encryption, copies the pinned template to
`/home/<user>/repos/nix-flake`, generates the hardware, user and host modules,
and finishes with `nixos-install --flake`.

The unattended ISO boots a minimal console, partitions the target with disko
(optionally wrapping the root in LUKS2), copies the template fork to
`/home/<user>/repos/nix-flake`, regenerates its hardware module and
`facter.json`, and runs `nixos-install --flake` without user interaction.
The modified flake is left in the installed system.

## Requirements

- Calamares ISO install: 4 GB RAM minimum.
- Unattended ISO install: 4 GB RAM minimum.
- `nix run .#setup` from `ojuny-template`: 4 GB RAM, because it builds the compiled packages from source.
- Network access for the online install paths. The offline ISOs do not need it.

## Build

```sh
nix build .#ojuny-iso
```

The image is written to `result/iso/*.iso`.

Build an offline full-system image:

```sh
nix build .#ojuny-iso-offline
```

The offline image is written to `result/iso/*.iso` and contains the full system
runtime closure.

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
and build command without building. Add `--offline` to build the full-system
offline image instead.

See `docs/unattended-install.md` for modes, the install flow and limitations.

## Test in QEMU

```sh
qemu-img create -f qcow2 /tmp/ojuny-test.qcow2 20G
firmware="$(nix build --no-link --print-out-paths nixpkgs#OVMF.fd)/FV/OVMF.fd"
iso="$(echo result/iso/*.iso)"

qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 4 -cpu host \
  -bios "$firmware" \
  -device virtio-vga-gl \
  -device virtio-keyboard-pci -device virtio-tablet-pci \
  -drive file="$iso",media=cdrom,readonly=on \
  -drive file=/tmp/ojuny-test.qcow2,if=virtio \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -display gtk,gl=on
```

The VM needs accelerated virtio graphics (`virtio-vga-gl` with `gl=on`).
Plain VGA, QXL and 2D `virtio-vga` render the Wayland session incorrectly.

The ISO has been confirmed to boot with 4 GB RAM and 2 threads. Install time on
that configuration has not been measured yet.

The online installer needs network access because `nixos-install` fetches the
template's flake inputs. The offline images carry the full system runtime
closure, so they install without network access. If a manual offline test finds
a missing build input, add that path explicitly instead of enabling the full
build-dependency closure. To test an offline image in QEMU, replace
`-netdev user,id=net0 -device virtio-net-pci,netdev=net0` with `-nic none`.

The Calamares ISO includes the compiled Ojuny GUI packages from the template's
locked nixpkgs. The installed system uses the same template lock, so those store
paths are reused. A prepared repository keeps its own lock and may rebuild them.

## Timings

- Calamares ISO install with LUKS2 root and XFS on a Ryzen 3 3200U with 24 GB
  RAM and a 256 GB NVMe SSD (generic SSD with a DRAM cache): 18 minutes.
- Full clean ISO build: 51 minutes.
- ISO rebuild with reused dependencies, rebuilding only the squashfs: 15
  minutes.

Most of the build time is spent pre-building the six compiled applications.

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

## Git credentials

The installer writes `~/.git-credentials` only when the selected repository URL
is HTTPS and a token is provided. The file is mode `0600`, and the repository
uses `credential.helper = store --file=/home/<user>/.git-credentials`. An SSH
clone uses the user's SSH key: it gets no helper and no credential file. The
file stays until the user removes it. This is the deferred secrets handling
boundary described in `ojuny-docs/canon/09-security.md`.

## Attended install tests

Attended results and the pending runs live in
[docs/attended-install.md](docs/attended-install.md). The prepared-repository
and git pre-setup checks are
`scripts/test-prepared-install.sh` and `scripts/test-git-presetup-install.sh`.
Both boot QEMU and inspect the installed disk afterwards. They are written but
not run yet.

## Layout

- `flake.nix`: inputs, dev shell, packages and the ISO outputs.
- `nixos/iso.nix`: live Calamares ISO configuration.
- `nixos/unattended.nix`: unattended installer ISO configuration.
- `nixos/full-iso.nix`: full-system offline Calamares ISO configuration.
- `nixos/full-unattended.nix`: full-system offline unattended ISO configuration.
- `nixos/full-system.nix`: full template module set without machine hardware.
- `nixos/full-hardware.nix`: generic hardware for the prebuilt target closure.
- `nixos/target-bootloader.nix`: systemd-boot for the prebuilt target closure.
- `nixos/offline.nix`: offline store, compression and size settings.
- `nixos/unattended-install.py`: unattended install service.
- `unattended/default-settings.nix`: unattended defaults.
- `scripts/make-unattended-iso.sh`: settings generator and ISO build wrapper.
- `scripts/test-prepared-install.sh`: QEMU check for a prepared template install.
- `scripts/test-git-presetup-install.sh`: QEMU check for the git pre-setup path.
- `docs/attended-install.md`: attended results and the pending run list.
- `packages/calamares-ojuny.nix`: Calamares wrapper pointing at our extensions.
- `packages/ojuny-calamares-extensions/`: settings, branding and the `ojuny`
  job module that installs the template.

## Limitations

- `x86_64-linux` only.
- UEFI uses systemd-boot; BIOS uses GRUB.
- Encrypted BIOS boot uses a generated GRUB keyfile and GRUB cryptodisk.
- The offline ISOs target under 8,000,000,000 bytes so an 8 GB USB can hold
  them. Check them with `scripts/check-iso-size.sh`.
- The unattended ISO wipes the configured disk without an interactive
  installer.
- The unattended ISO does not configure Wi-Fi. Use a wired connection.
