{ netbird-relay }:
{ lib, config, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;

  cfg = config.services.netbird-relay;
in
{
  options = {
    services.netbird-relay = {
      enable = mkEnableOption "Netbird Relay service";
      # should probably have a package option....

      authSecretFile = mkOption {
        type = types.str;
        description = "Path to the Netbird Relay auth secret file";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ netbird-relay ];

    systemd.services.netbird-relay = {
      enable = true;
      description = "Netbird Relay service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        EnvironmentFile = [ cfg.authSecretFile ];
        StateDirectory = "netbird-relay";
        ExecStart = "${lib.getExe netbird-relay} \
          --listen-address=:33080 \
          --exposed-address=rels://relay.netbird.alxandr.me:443 \
          --enable-stun \
          --stun-ports 3478 \
          --stun-log-level info \
          --log-file=console \
          --metrics-port=9090 \
          --health-listen-address=127.0.0.1:9000 \
          --letsencrypt-data-dir=/var/lib/netbird-relay \
          --letsencrypt-domains=relay.netbird.alxandr.me \
          --letsencrypt-email=\"alxandr@alxandr.me\"";
        Restart = "always";
        User = "netbird-relay";
        Group = "netbird-relay";
      };
    };

    users = {
      users.netbird-relay = {
        description = "Netbird Relay service user";
        group = "netbird-relay";
        isSystemUser = true;
      };
      groups.netbird-relay = { };
    };

    networking.nftables.tables."netbird-relay" = {
      family = "inet";
      content = ''
        chain prerouting {
          type nat hook prerouting priority -100; policy accept;
          udp dport 443 redirect to :33080
        }
      '';
    };

    networking.firewall.allowedUDPPorts = [
      3478
      33080
    ];
  };
}
