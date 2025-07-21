{ lib, config, ... }:
let
  inherit (lib)
    types
    mkOption
    mkMerge
    ;

  cfg = config.wg-bgp-mesh;
  secrets = config.sops.secrets;

  peerType = types.submodule (
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          description = "Name of the peer.";
          default = name;
        };

        internal.ipv4 = mkOption {
          type = types.str;
          description = "Internal IP address of the WireGuard peer.";
        };

        bgp.weight = mkOption {
          type = types.int;
          description = "BGP weight for the peer.";
          default = 200; # Default weight
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
    sops.secrets = mkMerge (
      lib.mapAttrsToList (name: peer: {
        "wg-bgp-mesh/${name}.peer.pub" = {
          sopsFile = ../secrets/pangolin/peers.yaml;
          format = "yaml";
          key = "peers/${name}/peerPublicKey";
        };
        "wg-bgp-mesh/${name}.own.key" = {
          sopsFile = ../secrets/pangolin/peers.yaml;
          format = "yaml";
          key = "peers/${name}/ownPrivateKey";
        };
        "wg-bgp-mesh/${name}.psk" = {
          sopsFile = ../secrets/pangolin/peers.yaml;
          format = "yaml";
          key = "peers/${name}/presharedKey";
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
          address = [ "${peer.internal.ipv4}/32" ];
        };
      }) cfg.peers)
    );

    networking.firewall.allowedUDPPorts = lib.mapAttrsToList (name: peer: peer.port) cfg.peers;
  };
}
