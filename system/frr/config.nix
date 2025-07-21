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

  peerList = lib.attrValues peers;

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
      neighbor ${peer.bgp.ipv4} remote-as ${builtins.toString peer.bgp.as}
      neighbor ${peer.bgp.ipv4} soft-reconfiguration inbound
      neighbor ${peer.bgp.ipv4} weight ${builtins.toString peer.bgp.weight}
    '') peerList}

    ! IPv4 config
    address-family ipv4 unicast
      ! Peers
      ${include "\n" "    " (peer: ''
        neighbor ${peer.bgp.ipv4} activate
      '') peerList}
    exit-address-family
''
