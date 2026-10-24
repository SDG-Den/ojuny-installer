{
  pkgs,
  calamares,
  extensions,
}:

pkgs.writeShellApplication {
  name = "ojuny-install";
  runtimeInputs = [ calamares ];
  text = ''
    export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"
    export XDG_DATA_DIRS="${extensions}/share:''${XDG_DATA_DIRS:-/run/current-system/sw/share}"
    export XDG_CONFIG_DIRS="${extensions}/etc:''${XDG_CONFIG_DIRS:-/etc/xdg}"
    export QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-wayland;xcb}"
    exec ${calamares}/bin/calamares --xdg-config "$@"
  '';
}
