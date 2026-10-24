{
  description = "Ojuny installer - Calamares live ISO and unattended installer ISO";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    ojuny-template = {
      url = "github:SDG-Den/ojuny-template";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    settings.url = "path:./unattended/default";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      settings = (import ./unattended/default-settings.nix) // (inputs.settings.settings or { });

      iso = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [ ./nixos/iso.nix ];
      };

      unattended = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs settings; };
        modules = [ ./nixos/unattended.nix ];
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ system ];

      perSystem =
        { pkgs, system, ... }:
        let
          ojuny-calamares-extensions = pkgs.callPackage ./packages/ojuny-calamares-extensions {
            templatePath = inputs.ojuny-template.outPath;
            prepareRepo = (inputs.ojuny-template.packages.${system} or { }).prepare-repo or null;
            regenerateHardware = (inputs.ojuny-template.packages.${system} or { }).regenerate-hardware or null;
            mkpasswd = pkgs.mkpasswd;
          };

          calamares-ojuny = pkgs.callPackage ./packages/calamares-ojuny.nix {
            extensions = ojuny-calamares-extensions;
          };
        in
        {
          formatter = pkgs.nixfmt;

          packages = {
            inherit ojuny-calamares-extensions calamares-ojuny;

            ojuny-iso = iso.config.system.build.isoImage;
            unattended-iso = unattended.config.system.build.isoImage;
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              cpio
              deadnix
              file
              git
              gzip
              jq
              mkpasswd
              nix
              nixd
              nixfmt
              OVMF
              python3
              python3Packages.pyyaml
              qemu
              shellcheck
              shfmt
              squashfsTools
              statix
              xorriso
              xz
              yq-go
              zstd
            ];
          };

          checks = {
            format = pkgs.runCommand "check-format" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
              cd ${./.}
              nixfmt --check flake.nix $(find packages nixos unattended -name '*.nix')
              touch $out
            '';

            extensions =
              pkgs.runCommand "check-ojuny-calamares-extensions" { nativeBuildInputs = [ pkgs.yq-go ]; }
                ''
                  yq -e '.branding == "ojuny"' ${ojuny-calamares-extensions}/etc/calamares/settings.conf
                  yq -e '.componentName == "ojuny"' ${ojuny-calamares-extensions}/share/calamares/branding/ojuny/branding.desc
                  yq -e '.slideshow == "show.qml"' ${ojuny-calamares-extensions}/share/calamares/branding/ojuny/branding.desc
                  test -f ${ojuny-calamares-extensions}/share/calamares/branding/ojuny/show.qml
                  grep -q 'notesqml@template' ${ojuny-calamares-extensions}/etc/calamares/settings.conf
                  grep -q 'notesqml@origin' ${ojuny-calamares-extensions}/etc/calamares/settings.conf
                  yq -e '.requirements.requiredStorage == 30' ${ojuny-calamares-extensions}/etc/calamares/modules/welcome.conf
                  yq -e '.requirements.required | contains(["storage"]) | not' ${ojuny-calamares-extensions}/etc/calamares/modules/welcome.conf
                  yq -e '.mkpasswd | length > 0' ${ojuny-calamares-extensions}/etc/calamares/modules/ojuny.conf
                  prepare_repo_path="$(yq -r '.prepareRepo' ${ojuny-calamares-extensions}/etc/calamares/modules/ojuny.conf)"
                  if [ -n "$prepare_repo_path" ]; then
                    case "$prepare_repo_path" in
                      */bin/prepare-repo) ;;
                      *) echo "prepareRepo is not an executable path: $prepare_repo_path"; exit 1 ;;
                    esac
                  fi
                  regenerate_path="$(yq -r '.regenerateHardware' ${ojuny-calamares-extensions}/etc/calamares/modules/ojuny.conf)"
                  if [ -n "$regenerate_path" ]; then
                    case "$regenerate_path" in
                      */bin/regenerate-hardware) ;;
                      *) echo "regenerateHardware is not an executable path: $regenerate_path"; exit 1 ;;
                    esac
                  fi
                  yq -e '.name == "ojuny" and .interface == "python"' ${ojuny-calamares-extensions}/lib/calamares/modules/ojuny/module.desc
                  test -f ${ojuny-calamares-extensions}/etc/calamares/modules/ojuny.conf
                  touch $out
                '';

            module = pkgs.runCommand "check-ojuny-calamares-module" { nativeBuildInputs = [ pkgs.python3 ]; } ''
              python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' \
                ${./packages/ojuny-calamares-extensions/modules/ojuny/main.py}
              touch $out
            '';

            unattended =
              pkgs.runCommand "check-ojuny-unattended"
                {
                  nativeBuildInputs = [
                    pkgs.python3
                    pkgs.shellcheck
                  ];
                }
                ''
                  python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' \
                    ${./nixos/unattended-install.py}
                  shellcheck -S warning ${./scripts/make-unattended-iso.sh}
                  touch $out
                '';
          };
        };

      flake.nixosConfigurations.ojuny-iso = iso;
      flake.nixosConfigurations.ojuny-unattended = unattended;
    };
}
