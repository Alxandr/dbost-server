{ pkgs, config, ... }:

let
  policyFile = (pkgs.formats.json { }).generate "policy.json" (import ./headscale/policy.nix);

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
      "pangolin.env" = {
        sopsFile = ../secrets/pangolin/pangolin.env;
        format = "dotenv";
        restartUnits = [ "pangolin.service" ];
      };
      "traefik.env" = {
        sopsFile = ../secrets/pangolin/traefik.env;
        format = "dotenv";
        restartUnits = [ "traefik.service" ];
      };
    };

    # Enable networking & firewall
    services.resolved.enable = true;
    networking.networkmanager.enable = true;
    networking.enableIPv6 = true;
    networking.nftables.enable = true;
    networking.firewall.enable = true;
    networking.firewall.allowedTCPPorts = [
      80 # HTTP
      443 # HTTPS
    ];
    networking.firewall.allowedUDPPorts = [
      41641
      3478
    ];

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
        policy.path = policyFile;
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
