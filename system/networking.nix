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

        interface = mkOption {
          type = types.str;
          description = "Name of the wireguard network interface.";
          default = "wg-${config.name}";
        };

        tunnel.local.address = mkOption {
          type = types.str;
          description = "Tunnel-internal IP CIDR of the WireGuard interface.";
        };

        tunnel.remote.address = mkOption {
          type = types.str;
          description = "Tunnel-internal IP CIDR of the WireGuard peer.";
        };

        tunnel.allowedIps = mkOption {
          type = types.listOf types.str;
          description = "Allowed IPs for the WireGuard tunnel.";
        };

        bgp.asn = mkOption {
          type = types.int;
          description = "BGP Autonomous System Number (ASN) for the peer.";
        };

        bgp.weight = mkOption {
          type = types.int;
          description = "BGP weight for the peer.";
          default = 200; # Default weight
        };

        bgp.address = mkOption {
          type = types.str;
          description = "Address of the BGP peer.";
          default = config.tunnel.remote.address;
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

    # services.frr = {
    #   bgpd.enable = true;
    #   bfdd.enable = true;
    #   config = import ./frr/config.nix {
    #     inherit lib;
    #     inherit (cfg) peers;
    #     router-id = "46.62.174.170";
    #     as = "65060";
    #     networks = [
    #       "46.62.174.170/32"
    #     ];
    #   };
    # };

    sops.secrets = mkMerge (
      lib.mapAttrsToList (name: peer: {
        "wg-bgp-mesh/${peer.name}.remote.pub" = {
          sopsFile = ../secrets/pangolin/wg-peers.yaml;
          format = "yaml";
          key = "${peer.name}/peerPublicKey";
          owner = "root";
          group = "systemd-network";
          mode = "0440";
          restartUnits = [ "systemd-networkd" ];
        };
        "wg-bgp-mesh/${peer.name}.own.key" = {
          sopsFile = ../secrets/pangolin/wg-peers.yaml;
          format = "yaml";
          key = "${peer.name}/ownPrivateKey";
          owner = "root";
          group = "systemd-network";
          mode = "0440";
          restartUnits = [ "systemd-networkd" ];
        };
        "wg-bgp-mesh/${peer.name}.psk" = {
          sopsFile = ../secrets/pangolin/wg-peers.yaml;
          format = "yaml";
          key = "${peer.name}/presharedKey";
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
        netdevs."50-wg-${peer.name}" = {
          netdevConfig.Kind = "wireguard";
          netdevConfig.Name = peer.interface;
          netdevConfig.MTUBytes = 1420; # Default MTU for WireGuard

          wireguardConfig.ListenPort = peer.port;
          wireguardConfig.PrivateKeyFile = secrets."wg-bgp-mesh/${peer.name}.own.key".path;

          wireguardPeers = [
            {
              AllowedIPs = peer.tunnel.allowedIps;
              PublicKeyFile = secrets."wg-bgp-mesh/${peer.name}.remote.pub".path;
              PresharedKeyFile = secrets."wg-bgp-mesh/${peer.name}.psk".path;
            }
          ];
        };
        networks."50-wg-${peer.name}" = {
          name = peer.interface;
          matchConfig.Name = peer.interface;
          linkConfig.RequiredForOnline = "no";
          addresses = [
            { Address = "${peer.tunnel.local.address}"; }
          ];
          routes = [ ];
        };
      }) cfg.peers)
    );

    networking.firewall.allowedUDPPorts = lib.mapAttrsToList (name: peer: peer.port) cfg.peers;
  };
}
