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

    exec pkexec ${pkgs.coreutils}/bin/env \
      XDG_DATA_DIRS="${extensions}/share:''${XDG_DATA_DIRS:-/run/current-system/sw/share}" \
      XDG_CONFIG_DIRS="${extensions}/etc:''${XDG_CONFIG_DIRS:-/etc/xdg}" \
      PATH="$PATH" \
      QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-wayland;xcb}" \
      DISPLAY="''${DISPLAY:-}" \
      WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-}" \
      XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-}" \
      DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-}" \
      XAUTHORITY="''${XAUTHORITY:-}" \
      ${calamares}/bin/calamares --xdg-config "$@"
  '';
}
