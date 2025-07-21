{ ... }:
{
  # Control Plane
  wg-bgp-mesh.peers."talos-n1-cp" = {
    port = 51971;
    tunnel.ipv4 = "192.168.60.151";
    internal.ipv4 = "192.168.41.60";
    bgp.as = 65001;
    bgp.weight = 100;
  };

  # Worker Nodes
  wg-bgp-mesh.peers."talos-n1-w1" = {
    port = 51981;
    tunnel.ipv4 = "192.168.60.161";
    internal.ipv4 = "192.168.41.71";
    bgp.as = 65001;
  };
  wg-bgp-mesh.peers."talos-n1-w2" = {
    port = 51982;
    tunnel.ipv4 = "192.168.60.162";
    internal.ipv4 = "192.168.41.72";
    bgp.as = 65001;
  };
}
