let
  accept = "accept";

in
{
  hosts = {
    pangolin = "46.62.174.170/32";
    taols-lb = "10.252.0.0/16";
  };

  acls = [
    {
      action = accept;
      src = [ "pangolin" ];
      dest = [ "talos-lb:80,443" ];
    }
  ];
}
