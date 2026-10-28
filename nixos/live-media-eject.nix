{
  config,
  lib,
  pkgs,
  ...
}:

let
  plymouthQuit = lib.optionalString config.boot.plymouth.enable ''
    ${lib.getExe' pkgs.coreutils "timeout"} 5 ${lib.getExe' config.boot.plymouth.package "plymouth"} quit --wait || true
  '';

  prompt = pkgs.writeShellScript "ojuny-live-media-eject" ''
    ${plymouthQuit}
    exec </dev/console >/dev/console 2>&1
    ${lib.getExe' pkgs.coreutils "stty"} sane 2>/dev/null || true
    printf '\nPlease remove the installation medium, then press ENTER.\n'
    read -r _ || true
  '';
in
{
  systemd.services.ojuny-live-media-eject = {
    description = "Prompt to remove the installation medium";
    wantedBy = [ "final.target" ];
    after = [
      "shutdown.target"
      "umount.target"
    ]
    ++ lib.optionals config.boot.plymouth.enable [
      "plymouth-reboot.service"
      "plymouth-poweroff.service"
      "plymouth-halt.service"
    ];
    before = [ "final.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "infinity";
      ExecStart = prompt;
    };
  };
}
