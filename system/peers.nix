{ lib, ... }:
let
  peers = lib.fromJSON (lib.readFile ./wg-peers.json);
in
{
  wg-bgp-mesh.peers = lib.attrsets.mapAttrs (name: peer: {
    interface = peer.iface;
    port = peer.port;
    bgp.peer.asn = peer.asn;
    bgp.holdTime = peer.holdTime;
    bgp.bfd =
      if (peer.bfd or null) == null then
        { }
      else
        {
          enable = true;
          transmitInterval = lib.elemAt peer.bfd.transmitInterval 0;
          transmitIntervalUnit = lib.elemAt peer.bfd.transmitInterval 1;
          receiveInterval = lib.elemAt peer.bfd.receiveInterval 0;
          receiveIntervalUnit = lib.elemAt peer.bfd.receiveInterval 1;
          detectMultiplier = peer.bfd.detectMultiplier;
        };
    bgp.import.prefixes = peer.importPrefixes;
    tunnel.local.address = peer.local.address;
    tunnel.remote.address = peer.remote.address;
    tunnel.allowedIps = peer.allowedIps;
  }) peers;
}
