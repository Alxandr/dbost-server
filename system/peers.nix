{ ... }:
{
  # Control Plane
  wg-bgp-mesh.peers."talos-n1-cp" = {
    port = 51971;
    internal.ipv4 = "192.168.60.151";
    bgp.as = 65001;
    bgp.weight = 100;
  };

  # Worker Nodes
  wg-bgp-mesh.peers."talos-n1-w1" = {
    port = 51981;
    internal.ipv4 = "192.168.60.161";
    bgp.as = 65001;
  };
  wg-bgp-mesh.peers."talos-n1-w2" = {
    port = 51982;
    internal.ipv4 = "192.168.60.162";
    bgp.as = 65001;
  };
}
