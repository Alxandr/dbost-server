{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    mkMerge
    ;

  cfg = config.wg-bgp-mesh;
  secrets = config.sops.secrets;

  peerType = types.submodule (
    { config, name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          description = "Name of the peer.";
          default = name;
        };

        tunnel.local.ipv4 = mkOption {
          type = types.str;
          description = "Tunnel-internal IP address of the WireGuard interface.";
        };

        tunnel.peer.ipv4 = mkOption {
          type = types.str;
          description = "Tunnel-internal IP address of the WireGuard peer.";
        };

        internal.ipv4 = mkOption {
          type = types.str;
          description = "Internal (NAT) IP address of the WireGuard peer.";
        };

        bgp.as = mkOption {
          type = types.int;
          description = "BGP Autonomous System Number (ASN) for the peer.";
        };

        bgp.weight = mkOption {
          type = types.int;
          description = "BGP weight for the peer.";
          default = 200; # Default weight
        };

        bgp.ipv4 = mkOption {
          type = types.str;
          description = "IPv4 address of the BGP peer.";
          default = config.tunnel.peer.ipv4;
        };

        port = mkOption {
          type = types.port;
          description = "Port for the WireGuard peer to connect to.";
        };
      };
    }
  );
in
{
  options.wg-bgp-mesh = {
    peers = mkOption {
      type = types.attrsOf peerType;
    };
  };

  config = {
    boot.kernelModules = [ "wireguard" ];
    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];

    services.frr = {
      bgpd.enable = true;
      bfdd.enable = true;
      config = import ./frr/config.nix {
        inherit lib;
        inherit (cfg) peers;
        router-id = "46.62.174.170";
        as = "65060";
        networks = [
          "46.62.174.170/32"
        ];
      };
    };

    sops.secrets = mkMerge (
      lib.mapAttrsToList (name: peer: {
        "wg-bgp-mesh/${name}.peer.pub" = {
          sopsFile = ../secrets/pangolin/peers.yaml;
          format = "yaml";
          key = "peers/${name}/peerPublicKey";
          owner = "root";
          group = "systemd-network";
          mode = "0440";
          restartUnits = [ "systemd-networkd" ];
        };
        "wg-bgp-mesh/${name}.own.key" = {
          sopsFile = ../secrets/pangolin/peers.yaml;
          format = "yaml";
          key = "peers/${name}/ownPrivateKey";
          owner = "root";
          group = "systemd-network";
          mode = "0440";
          restartUnits = [ "systemd-networkd" ];
        };
        "wg-bgp-mesh/${name}.psk" = {
          sopsFile = ../secrets/pangolin/peers.yaml;
          format = "yaml";
          key = "peers/${name}/presharedKey";
          owner = "root";
          group = "systemd-network";
          mode = "0440";
          restartUnits = [ "systemd-networkd" ];
        };
      }) cfg.peers
    );

    systemd.network = mkMerge (
      [ { enable = true; } ]
      ++ (lib.mapAttrsToList (name: peer: {
        netdevs."50-wg-${name}" = {
          netdevConfig.Kind = "wireguard";
          netdevConfig.Name = "wg-${name}";
          netdevConfig.MTUBytes = 1420; # Default MTU for WireGuard

          wireguardConfig.ListenPort = peer.port;
          wireguardConfig.PrivateKeyFile = secrets."wg-bgp-mesh/${name}.own.key".path;

          wireguardPeers = [
            {
              AllowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];
              PublicKeyFile = secrets."wg-bgp-mesh/${name}.peer.pub".path;
              # PresharedKeyFile = secrets."wg-bgp-mesh/${name}.psk".path;
            }
          ];
        };
        networks."50-wg-${name}" = {
          name = "wg-${name}";
          matchConfig.Name = "wg-${name}";
          address = [
            "${peer.tunnel.local.ipv4}/31"
            "192.168.60.1/32"
          ];
          routes = [ ];
        };
      }) cfg.peers)
    );

    networking.firewall.allowedUDPPorts = lib.mapAttrsToList (name: peer: peer.port) cfg.peers;
  };
}
