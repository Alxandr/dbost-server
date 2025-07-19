{ pkgs, config, ... }:

let
  policyFile = (pkgs.formats.json { }).generate "policy.json" (import ./headscale/policy.nix);
  wireguardPort = 51820;

in
{
  config = {
    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Enable the qemu guest agent
    services.qemuGuest.enable = true;

    # Decrypt secrets
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    sops.secrets = {
      "wg0.key" = {
        sopsFile = ../secrets/pangolin/wg0.yaml;
        format = "yaml";
        key = "key";
      };
      "wg0.talos-n1-cp.psk" = {
        sopsFile = ../secrets/pangolin/wg0.yaml;
        format = "yaml";
        key = "peers/talos-n1-cp/presharedKey";
      };
      "wg0.talos-n1-w1.psk" = {
        sopsFile = ../secrets/pangolin/wg0.yaml;
        format = "yaml";
        key = "peers/talos-n1-w1/presharedKey";
      };
      "wg0.talos-n1-w2.psk" = {
        sopsFile = ../secrets/pangolin/wg0.yaml;
        format = "yaml";
        key = "peers/talos-n1-w2/presharedKey";
      };
    };

    # Enable networking & firewall
    services.resolved.enable = true;
    networking = {
      networkmanager.enable = true;
      enableIPv6 = true;
      nftables.enable = true;
      wireguard.enable = true;

      # Firewall
      firewall.enable = true;
      firewall.allowedTCPPorts = [
        80 # HTTP
        443 # HTTPS
        wireguardPort
      ];
      firewall.allowedUDPPorts = [
        41641
        3478
        wireguardPort
      ];

      # Interfaces
      interfaces.enp1s0.ipv4 = {
        addresses = [
          {
            address = "46.62.174.170";
            prefixLength = 32;
          }
        ];
      };

      interfaces.enp1s0.ipv6 = {
        addresses = [
          {
            address = "2a01:4f9:c012:d5e9::";
            prefixLength = 64;
          }
        ];
      };

      wireguard.interfaces.wg0 = {
        # Determines the IP address and subnet of the server's end of the tunnel interface.
        ips = [ "192.168.60.1/24" ];
        mtu = 1420; # Default MTU for WireGuard

        # The port that WireGuard listens to. Must be accessible by the clients.
        listenPort = wireguardPort;

        # TODO: Masquerade?

        # Path to the private key file.
        privateKeyFile = config.sops.secrets."wg0.key".path;

        # List of allowed peers.
        peers = [
          {
            name = "talos-n1-cp";
            allowedIPs = [ "192.168.60.151/32" ];
            publicKey = "9WWQQ0n/Jd+dxgm1lbCvUyuzC/Tfe7i0ys0ruL0ycRE=";
            presharedKeyFile = config.sops.secrets."wg0.talos-n1-cp.psk".path;
          }
          {
            name = "talos-n1-w1";
            allowedIPs = [ "192.168.60.161/32" ];
            publicKey = "rFE3DTVc4JSzjMMSeUipVR+ELgvIJKDRbhzceKbPz08=";
            presharedKeyFile = config.sops.secrets."wg0.talos-n1-w1.psk".path;
          }
          {
            name = "talos-n1-w2";
            allowedIPs = [ "192.168.60.162/32" ];
            publicKey = "sNbXQB0mMpPLgMEPQ+/flXiG1nMVpkE/b38e4SHL9wk=";
            presharedKeyFile = config.sops.secrets."wg0.talos-n1-w2.psk".path;
          }
        ];
      };

      # Default gateways
      defaultGateway = {
        address = "172.31.1.1";
        interface = "enp1s0";
      };

      defaultGateway6 = {
        address = "fe80::1";
        interface = "enp1s0";
      };
    };

    # Enable SSH
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [ "alxandr" ];
        UseDns = true;
        X11Forwarding = false;
      };
    };

    # Enable sshguard
    services.sshguard = {
      enable = true;
      whitelist = [
        "home.alxandr.me"
      ];
    };

    # Enable Headscale
    services.headscale = {
      enable = true;
      settings = {
        server_url = "https://headscale.alxandr.me";
        prefixes.allocation = "random";
        dns = {
          magic_dns = true;
          base_domain = "tailnet.alxandr.me";
          nameservers.global = [ ];
          override_local_dns = false;
        };
        # policy.path = policyFile;
      };
    };

    # Enable Tailscale
    services.tailscale = {
      enable = true;
      disableTaildrop = true;
      openFirewall = true;
      # useRoutingFeatures = "server";
      # extraSetFlags = [
      #   "--accept-dns=false"
      # ];
    };

    # Enable envoy
    services.caddy = {
      enable = true;
      configFile = ./Caddyfile;
    };

    # Setup auto-upgrade
    system.autoUpgrade = {
      enable = true;
      operation = "boot";
      dates = "04:00";
      randomizedDelaySec = "45min";
      allowReboot = true;
      rebootWindow.lower = "04:00";
      rebootWindow.upper = "06:00";
    };

    environment.systemPackages = with pkgs; [
      yq-go
      jq
      caddy
    ];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
