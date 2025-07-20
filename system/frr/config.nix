{
  lib,
  router-id,
  as,
  peers,
  networks,
}:

let
  include =
    sep: prefix: fn: items:
    let
      blocks = lib.map fn items;
      trimmed = lib.map (block: lib.trim block) blocks;
      combined = lib.concatStringsSep sep trimmed;
      lines = lib.splitString "\n" combined;
      firstLine = lib.head lines;
      restLines = lib.tail lines;
      prefixedRestLines = lib.map (line: lib.trimWith { end = true; } "${prefix}${line}") restLines;
      prefixedLines = [ firstLine ] ++ prefixedRestLines;
    in
    lib.concatStringsSep "\n" prefixedLines;

in
''
  frr defaults datacenter

  router bgp ${as}
    bgp router-id ${router-id}
    bgp fast-convergence
    no bgp default ipv4-unicast
    no bgp ebgp-requires-policy

    ${include "\n\n" "  " (peer: ''
      ! Peer: ${peer.name}
      neighbor ${peer.bgp.ip} remote-as ${peer.bgp.as}
      neighbor ${peer.bgp.ip} soft-reconfiguration inbound
      neighbor ${peer.bgp.ip} weight ${builtins.toString peer.bgp.weight}
    '') peers}

    ! IPv4 config
    address-family ipv4 unicast
      ! Networks
      ${include "\n" "    " (network: ''
        network ${network}
      '') networks}

      ! Peers
      ${include "\n" "    " (peer: ''
        neighbor ${peer.bgp.ip} activate
      '') peers}
    exit-address-family
''
