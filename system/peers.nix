{ lib, ... }:
let
  peers = lib.fromJSON (lib.readFile ./wg-peers.json);
in
{
  wg-bgp-mesh.peers = lib.attrsets.mapAttrs (name: peer: {
    interface = peer.iface;
    port = peer.port;
    bgp.asn = peer.asn;
    tunnel.local.address = peer.local.address;
    tunnel.remote.address = peer.remote.address;
    tunnel.allowedIps = peer.allowedIps;
  }) peers;
}
