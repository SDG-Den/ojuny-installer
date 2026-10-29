{
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:

let
  extensions = pkgs.callPackage ../packages/ojuny-calamares-extensions {
    templatePath = inputs.ojuny-template.outPath;
    prepareRepo = (inputs.ojuny-template.packages.${pkgs.system} or { }).prepare-repo or null;
    regenerateHardware =
      (inputs.ojuny-template.packages.${pkgs.system} or { }).regenerate-hardware or null;
    mkpasswd = pkgs.mkpasswd;
  };

  calamaresPkg = pkgs.calamares.overrideAttrs (previous: {
    patches = lib.filter (patch: !(lib.hasInfix "dont-allow-manual-luks" (toString patch))) (
      previous.patches or [ ]
    );
  });

  calamares = pkgs.callPackage ../packages/calamares-ojuny.nix {
    calamares = calamaresPkg;
    inherit extensions;
  };
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
    ./live-media-eject.nix

    inputs.ojuny-template.modules.nixos.system-graphics
    inputs.ojuny-template.modules.nixos.desktop-mango
    inputs.ojuny-template.modules.nixos.desktop-mangosettings
    inputs.ojuny-template.modules.nixos.desktop-mangomaster
    inputs.ojuny-template.modules.nixos.desktop-mangodwindle
    inputs.ojuny-template.modules.nixos.desktop-mangoworkspaces
    inputs.ojuny-template.modules.nixos.desktop-scroller
    inputs.ojuny-template.modules.nixos.desktop-display
    inputs.ojuny-template.modules.nixos.desktop-style-theme
    inputs.ojuny-template.modules.nixos.desktop-style-typography
    inputs.ojuny-template.modules.nixos.desktop-style-compositor
    inputs.ojuny-template.modules.nixos.desktop-style-shell
    inputs.ojuny-template.modules.nixos.desktop-bar
    inputs.ojuny-template.modules.nixos.desktop-dock
    inputs.ojuny-template.modules.nixos.desktop-dashboard
    inputs.ojuny-template.modules.nixos.desktop-notifications
    inputs.ojuny-template.modules.nixos.desktop-clipboard
    inputs.ojuny-template.modules.nixos.desktop-menu
    inputs.ojuny-template.modules.nixos.desktop-plugins
    inputs.ojuny-template.modules.nixos.desktop-binds
    inputs.ojuny-template.modules.nixos.desktop-autostart
    inputs.ojuny-template.modules.nixos.desktop-input
    inputs.ojuny-template.modules.nixos.desktop-controlcenter
    inputs.ojuny-template.modules.nixos.desktop-gestures
    inputs.ojuny-template.modules.nixos.desktop-launcher

    inputs.nix-cache-discovery.nixosModules.default
  ];

  services.nix-cache-discovery = {
    enable = true;
    exclusive = true;
    port = 5055;

    # Switch to discovery.auto = true once the cache revision with that option
    # is published. Until then the live ISO scans the common private range.
    discovery.ranges = [ "192.168.0.0/16" ];
    discovery.interval = 60;
  };

  documentation.enable = lib.mkForce false;
  documentation.man.enable = lib.mkForce false;
  documentation.doc.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkForce false;

  environment.defaultPackages = lib.mkForce [
    pkgs.vim
    pkgs.nano
    pkgs.mesa-demos
  ];

  nixpkgs.overlays = [
    (final: prev: {
      glibcLocales = prev.glibcLocalesUtf8;
    })
    (final: prev: {
      khal = prev.khal.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          mkdir -p $man
        '';
      });

      tesseract = prev.tesseract.override {
        enableLanguages = [ "eng" ];
      };
    })
  ];

  system.nixos.distroName = "Ojuny";
  system.nixos.distroId = "ojuny";

  ojuny.gpu = lib.mkForce "none";

  isoImage.edition = lib.mkForce "installer-discovery";
  isoImage.volumeID = lib.mkForce "OJUNY_DISCOVERY";
  image.baseName = lib.mkForce "ojuny-discovery";

  desktop.ojuny.mango.execOnce = lib.mkForce [
    "dms run"
    "wl-clip-persist --clipboard both"
    "wl-paste --type text --watch cliphist store"
    "wl-paste --type image --watch cliphist store"
    "ydotoold"
    "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE"
    "systemctl --user reset-failed"
    "systemctl --user start mango-session.target"
  ];

  desktop.ojuny.mango.rules.window_rule = [
    {
      app_id = "calamares";
      is_floating = 1;
      width = 0.8;
      height = 0.8;
    }
    {
      title = "Calamares";
      is_floating = 1;
      width = 0.8;
      height = 0.8;
    }
  ];

  desktop.ojuny.mango.binds.common = {
    focusDown = {
      modifier = [
        "CTRL"
        "ALT"
      ];
      keys = [ "delete" ];
      dispatcher = "spawn_shell";
      args = "ghostty";
      description = "ctrl+alt+delete ghostty bind";
      group = "debug";
    };
  };

  services.displayManager.ly.enable = true;
  services.displayManager.defaultSession = "ojuny";
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  services.speechd.enable = lib.mkForce false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  security.polkit.enablePkexecWrapper = true;
  programs.partition-manager.enable = true;
  i18n.supportedLocales = lib.mkForce [
    "en_US.UTF-8/UTF-8"
    "nl_NL.UTF-8/UTF-8"
  ];

  environment.systemPackages = [
    calamares
    (pkgs.makeDesktopItem {
      name = "ojuny-install";
      desktopName = "Install Ojuny";
      exec = "${calamares}/bin/ojuny-install";
      icon = "system-software-install";
      categories = [ "System" ];
      terminal = false;
    })
    pkgs.cryptsetup
    pkgs.glibcLocales
    pkgs.mkpasswd
    pkgs.nixos-facter
    pkgs.zsh
  ];

  services.upower.enable = true;

  systemd.user.services.ojuny-install = {
    description = "Ojuny Calamares installer";
    wantedBy = [ "mango-session.target" ];
    after = [ "graphical-session.target" ];
    environment.QT_QPA_PLATFORM = "wayland;xcb";
    serviceConfig = {
      ExecStart = "${calamares}/bin/ojuny-install";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
