{
  lib,
  pkgs,
  config,
  ...
}:

with lib;
let
  cfg = config.services.netmaker;

in
{
  options.services.netmaker = {
    enable = mkEnableOption "Netmaker service";
    package = mkPackageOption pkgs "netmaker" { };
    configFile = mkOption {
      type = types.path;
      description = ''
        Path to the Netmaker configuration file.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Open ports in the firewall for the Netmaker service.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.groups.netmaker = { };
    users.users.netmaker = {
      group = "netmaker";
      isSystemUser = true;
    };

    systemd.services.netmaker = {
      description = "Netmaker Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        # ExecStart = "${cfg.package}/bin/netmaker -c ${cfg.configFile}";
        ExecStart = "${pkgs.netmaker}/bin/netmaker";
        User = "netmaker";

        EnvironmentFile = [ cfg.configFile ];
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedUDPPorts = [
        51821 # Netmaker WireGuard port
        443 # Netmaker HTTPS port ??
      ];
    };
  };
}
