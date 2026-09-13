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

        bgp.self.asn = mkOption {
          type = types.int;
          description = "BGP Autonomous System Number (ASN) for self.";
          default = 65010;
        };

        bgp.peer.asn = mkOption {
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

        bgp.holdTime = mkOption {
          type = types.int;
          description = "BGP hold time for the peer.";
        };

        bgp.bfd.enable = mkOption {
          type = types.bool;
          description = "Enable BFD for the BGP peer.";
          default = false;
        };

        bgp.bfd.transmitInterval = mkOption {
          type = types.int;
          description = "BFD transmit interval for the BGP peer.";
          default = 1;
        };

        bgp.bfd.transmitIntervalUnit = mkOption {
          type = types.str;
          description = "BFD transmit interval unit for the BGP peer.";
          default = "s";
        };

        bgp.bfd.receiveInterval = mkOption {
          type = types.int;
          description = "BFD receive interval for the BGP peer.";
          default = 1;
        };

        bgp.bfd.receiveIntervalUnit = mkOption {
          type = types.str;
          description = "BFD receive interval unit for the BGP peer.";
          default = "s";
        };

        bgp.bfd.detectMultiplier = mkOption {
          type = types.int;
          description = "BFD detect multiplier for the BGP peer.";
          default = 3;
        };

        bgp.import.prefixes = mkOption {
          type = types.listOf types.str;
          description = "BGP import prefixes for the peer.";
        };

        # bgp.export.prefixes = mkOption {
        #   type = types.nullOr (types.listOf types.str);
        #   description = "BGP export prefixes for the peer.";
        #   default = null;
        # };

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
    routerId = mkOption {
      type = types.str;
      description = "Router ID for the BGP mesh.";
      default = "46.62.174.170";
    };

    peers = mkOption {
      type = types.attrsOf peerType;
    };
  };

  config = {
    boot.kernelModules = [ "wireguard" ];
    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];

    services.bird = {
      enable = true;
      config = pkgs.callPackage ./bird-config.nix { config = cfg; };
    };

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
