{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  settings,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;

  disko = inputs.disko.packages.${system}.disko;
  regenerateHardware = inputs.ojuny-template.packages.${system}.regenerate-hardware;
  prepareRepo = inputs.ojuny-template.packages.${system}.prepare-repo;

  swapPartition = lib.optionalAttrs (settings.swapSize != null && settings.swapSize != "0") {
    swap = {
      size = settings.swapSize;
      priority = 3;
      content = {
        type = "swap";
      };
    };
  };

  diskConfig = {
    disko.devices.disk.main = {
      device = settings.disk;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02";
            priority = 1;
          };
          ESP = {
            size = "1G";
            type = "EF00";
            priority = 2;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            priority = 4;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        }
        // swapPartition;
      };
    };
  };
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  system.nixos.distroName = "Ojuny";

  isoImage.edition = "unattended";
  image.baseName = lib.mkForce "ojuny-unattended";
  isoImage.makeBiosBootable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.etc."ojuny/flake".source = inputs.ojuny-template.outPath;
  environment.etc."ojuny/disk-config.nix".text = lib.generators.toPretty { } diskConfig;
  environment.etc."ojuny/settings.json" = {
    mode = "0600";
    text = builtins.toJSON settings;
  };
  environment.etc."ojuny/install.py".source = ./unattended-install.py;

  environment.systemPackages = [
    disko
    prepareRepo
    regenerateHardware
    pkgs.curl
    pkgs.dosfstools
    pkgs.e2fsprogs
    pkgs.git
    pkgs.gptfdisk
    pkgs.jq
    pkgs.nix
    pkgs.nixos-install-tools
    pkgs.parted
    pkgs.python3
    pkgs.util-linux
  ];

  systemd.services.ojuny-unattended-install = {
    description = "Ojuny unattended installation";
    wantedBy = [ "multi-user.target" ];
    after = [
      "local-fs.target"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    conflicts = [ "getty@tty1.service" ];
    path = [
      disko
      prepareRepo
      regenerateHardware
      pkgs.curl
      pkgs.dosfstools
      pkgs.e2fsprogs
      pkgs.git
      pkgs.gptfdisk
      pkgs.jq
      pkgs.nix
      pkgs.nixos-install-tools
      pkgs.parted
      pkgs.python3
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      TTYPath = "/dev/tty1";
      StandardInput = "tty-force";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
      ExecStart = "${pkgs.python3}/bin/python3 /etc/ojuny/install.py";
      TimeoutStartSec = "0";
      RemainAfterExit = true;
    };
  };

  assertions = [
    {
      assertion = settings.disk != null && lib.hasPrefix "/dev/" settings.disk;
      message = "unattended.disk must be a /dev path";
    }
    {
      assertion = builtins.elem settings.firmware [
        "efi"
        "bios"
      ];
      message = "unattended.firmware must be efi or bios";
    }
    {
      assertion = builtins.elem settings.mode [
        "prepared"
        "bundled"
      ];
      message = "unattended.mode must be prepared or bundled";
    }
    {
      assertion = builtins.elem settings.finalAction [
        "reboot"
        "poweroff"
      ];
      message = "unattended.finalAction must be reboot or poweroff";
    }
  ];
}
