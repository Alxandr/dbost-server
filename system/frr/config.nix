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

  ! Defines a prefix-list for Talos LB address space
  ip prefix-list talos-lb seq 5 permit 10.252.0.0/16 le 32

  ! Creates a route-map that permits only Talos LB addresses
  route-map talos-lb permit 10
    match ip address prefix-list talos-lb

  ! Deny everything else
  route-map talos-lb deny 10

  router bgp ${as}
    bgp router-id ${router-id}
    bgp fast-convergence
    bgp ebgp-requires-policy
    no bgp default ipv4-unicast

    ${include "\n\n" "  " (peer: ''
      ! Peer: ${peer.name}
      neighbor ${peer.bgp.ipv4} remote-as ${builtins.toString peer.bgp.as}
      neighbor ${peer.bgp.ipv4} soft-reconfiguration inbound
      neighbor ${peer.bgp.ipv4} weight ${builtins.toString peer.bgp.weight}
      neighbor ${peer.bgp.ipv4} route-map talos-lb in
    '') peerList}

    ! IPv4 config
    address-family ipv4 unicast
      ! Peers
      ${include "\n" "    " (peer: ''
        neighbor ${peer.bgp.ipv4} activate
      '') peerList}
    exit-address-family
''
