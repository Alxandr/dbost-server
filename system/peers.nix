{ ... }:
{
  # Control Plane
  wg-bgp-mesh.peers."pve1" = {
    port = 51821;
    tunnel.local.ipv4 = "192.168.60.11/31";
    tunnel.peer.ipv4 = "192.168.60.10/31";
    bgp.as = 65000;
  };

  wg-bgp-mesh.peers."pve2" = {
    port = 51822;
    tunnel.local.ipv4 = "192.168.60.13/31";
    tunnel.peer.ipv4 = "192.168.60.12/31";
    bgp.as = 65000;
  };
}
