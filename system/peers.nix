{ ... }:
{
  # Control Plane
  wg-bgp-mesh.peers."pve1" = {
    port = 51821;
    tunnel.local.ipv4 = "192.168.60.11/31";
    tunnel.peer.ipv4 = "192.168.60.10/31";
    bgp.as = 65000;
  };
}
