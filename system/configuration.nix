{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./networking.nix
    ./peers.nix
    ./netmaker.nix
  ];

  config = {
    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Enable the qemu guest agent
    services.qemuGuest.enable = true;

    # Decrypt secrets
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    sops.secrets = {
      "netmaker/netmaker.env" = {
        sopsFile = ../secrets/pangolin/netmaker.env;
        format = "dotenv";
        owner = "netmaker";
        group = "netmaker";
        mode = "0400";
        restartUnits = [ "netmaker" ];
      };
    };

    # Enable networking & firewall
    services.resolved.enable = true;
    systemd.network = {
      enable = true;
      networks."40-enp1s0" = {
        name = "enp1s0";
        matchConfig.Name = "enp1s0";
        address = [
          "46.62.174.170/32"
          "2a01:4f9:c012:d5e9::/64"
        ];
        routes = [
          {
            Gateway = "172.31.1.1";
            GatewayOnLink = true;
          }
          { Gateway = "fe80::1"; }
        ];
        # What is this?
        networkConfig.IPv6PrivacyExtensions = "kernel";
        networkConfig.DHCP = "no";
      };
    };
    networking = {
      useNetworkd = true;
      useDHCP = false;
      enableIPv6 = true;
      nftables.enable = true;

      # Firewall
      firewall.enable = true;
      firewall.allowedTCPPorts = [
        179 # BGP
        80 # HTTP
        443 # HTTPS
      ];
      firewall.allowedUDPPorts = [
        41641
        3478
      ];
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

    # Enable Netmaker
    services.netmaker = {
      enable = true;
      configFile = config.sops.secrets."netmaker/netmaker.env".path;
    };

    # Enable sshguard
    services.sshguard = {
      enable = true;
      whitelist = [
        "home.alxandr.me"
      ];
    };

    # Enable caddy
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
