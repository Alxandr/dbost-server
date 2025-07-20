{ lib, secrets }:

let
  mkNode =
    { weight }:
    {
      name,
      ip,
      wg,
    }:
    {
      inherit name ip;
      wg = {
        inherit name;
        inherit (wg)
          publicKey
          # presharedKeyFile
          ;
        allowedIPs = [
          "${ip}/32"
        ];
      };
      bgp = {
        inherit ip weight;
        as = "65001";
      };
    };

  mkCp = mkNode { weight = 100; };
  mkW = mkNode { weight = 200; };

  cp = lib.map mkCp [
    {
      name = "talos-n1-cp";
      ip = "192.168.60.151";
      wg.publicKey = "9WWQQ0n/Jd+dxgm1lbCvUyuzC/Tfe7i0ys0ruL0ycRE=";
      wg.presharedKeyFile = secrets."wg0.talos-n1-cp.psk".path;
    }
  ];
  w = lib.map mkW [
    {
      name = "talos-n1-w1";
      ip = "192.168.60.161";
      wg.publicKey = "rFE3DTVc4JSzjMMSeUipVR+ELgvIJKDRbhzceKbPz08=";
      wg.presharedKeyFile = secrets."wg0.talos-n1-w1.psk".path;
    }
    {
      name = "talos-n1-w2";
      ip = "192.168.60.162";
      wg.publicKey = "sNbXQB0mMpPLgMEPQ+/flXiG1nMVpkE/b38e4SHL9wk=";
      wg.presharedKeyFile = secrets."wg0.talos-n1-w2.psk".path;
    }
  ];
in

cp ++ w
