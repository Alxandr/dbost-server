{ lib, config, ... }:
let
  peers = config.peers;
  peerBlocks = lib.mapAttrsToList (_: peer: ''
    protocol bgp bgp_${lib.replaceStrings [ "-" ] [ "_" ] peer.name} {
      description "${peer.name}";

      local ${lib.head (lib.strings.split "/" peer.tunnel.local.address)} as ${lib.toString peer.bgp.self.asn};
      neighbor ${lib.head (lib.strings.split "/" peer.tunnel.remote.address)} as ${lib.toString peer.bgp.peer.asn};
      interface "${peer.interface}";
      direct;
      strict bind yes;
      passive on;

      ${lib.optionalString peer.bgp.bfd.enable ''
        bfd {
          min tx interval ${lib.toString peer.bgp.bfd.transmitInterval} ${peer.bgp.bfd.transmitIntervalUnit};
          min rx interval ${lib.toString peer.bgp.bfd.receiveInterval} ${peer.bgp.bfd.receiveIntervalUnit};
          multiplier ${lib.toString peer.bgp.bfd.detectMultiplier};
        };
      ''}

      ipv6 {
        import filter {
          if net ~ [ ${lib.concatStringsSep ", " peer.bgp.import.prefixes} ] then accept;

          reject;
        };

        export none;
      };
    }
  '') peers;
in
''
  router id ${config.routerId};

  protocol device {}

  protocol bfd { debug all; }

  protocol kernel kernel_ipv6 {
    merge paths on;

    ipv6 {
      import none;
      export all;
    };
  }

  ${lib.concatStringsSep "\n" peerBlocks}
''
