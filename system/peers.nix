{ lib, ... }:
let
  peers = lib.fromJSON (lib.readFile ./wg-peers.json);
in
{
  wg-bgp-mesh.peers = lib.attrsets.mapAttrs (name: peer: {
    interface = peer.iface;
    port = peer.port;
    bgp.peer.asn = peer.asn;
    bgp.import.prefixes = peer.importPrefixes;
    tunnel.local.address = peer.local.address;
    tunnel.remote.address = peer.remote.address;
    tunnel.allowedIps = peer.allowedIps;
  }) peers;
}
