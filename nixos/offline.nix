{
  inputs,
  lib,
  ...
}:

let
  flakeInputs = map (node: node.input.outPath) (
    builtins.genericClosure {
      startSet = [
        {
          key = inputs.ojuny-template.outPath;
          input = inputs.ojuny-template;
        }
      ];
      operator =
        node:
        map (input: {
          key = input.outPath;
          inherit input;
        }) (builtins.attrValues (node.input.inputs or { }));
    }
  );
in
{
  nix.settings.substituters = lib.mkForce [ ];
  nix.settings.extra-substituters = lib.mkForce [ ];
  nix.settings.trusted-substituters = lib.mkForce [ ];
  nix.settings.flake-registry = lib.mkForce "";

  environment.etc."ojuny/offline".text = "";

  isoImage.storeContents = lib.mkAfter flakeInputs;

  isoImage.compressImage = false;
  isoImage.squashfsCompression = "zstd -Xcompression-level 19";
}
