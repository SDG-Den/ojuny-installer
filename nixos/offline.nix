{ lib, ... }:

{
  nix.settings.substituters = lib.mkForce [ ];
  nix.settings.extra-substituters = lib.mkForce [ ];
  nix.settings.trusted-substituters = lib.mkForce [ ];
  nix.settings.flake-registry = lib.mkForce "";

  environment.etc."ojuny/offline".text = "";

  isoImage.compressImage = false;
  isoImage.squashfsCompression = "zstd -Xcompression-level 19";
}
