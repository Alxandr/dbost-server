{ ... }:
{
  # Control Plane
  wg-bgp-mesh.peers."talos-n1-cp" = {
    port = 51971;
    tunnel.local.ipv4 = "192.168.60.10";
    tunnel.peer.ipv4 = "192.168.60.11";
    internal.ipv4 = "192.168.41.60";
    bgp.as = 65001;
    bgp.weight = 100;
  };

  # Worker Nodes
  wg-bgp-mesh.peers."talos-n1-w1" = {
    port = 51981;
    tunnel.local.ipv4 = "192.168.60.50";
    tunnel.peer.ipv4 = "192.168.60.51";
    internal.ipv4 = "192.168.41.71";
    bgp.as = 65001;
  };
  wg-bgp-mesh.peers."talos-n1-w2" = {
    port = 51982;
    tunnel.local.ipv4 = "192.168.60.52";
    tunnel.peer.ipv4 = "192.168.60.53";
    internal.ipv4 = "192.168.41.72";
    bgp.as = 65001;
  };
}
