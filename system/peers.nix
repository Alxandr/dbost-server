{ ... }:
{
  # Control Plane
  wg-bgp-mesh.peers."talos-n1-cp" = {
    port = 51821;
    internal.ipv4 = "192.168.60.151";
    bgp.weight = 100;
  };

  # Worker Nodes
  wg-bgp-mesh.peers."talos-n1-w1" = {
    port = 51822;
    internal.ipv4 = "192.168.60.161";
  };
  wg-bgp-mesh.peers."talos-n1-w2" = {
    port = 51823;
    internal.ipv4 = "192.168.60.162";
    bgp.weight = 100;
  };
}
