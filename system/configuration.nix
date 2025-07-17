{ pkgs, ... }:
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
        # restartUnits = [ "pangolin.service" ];
      };
    };

    # Enable networking
    networking.networkmanager.enable = true;

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

    # Pangolin
    services.pangolin = {
      # enable = true;
      baseDomain = "alxandr.me";
      dashboardDomain = "pangolin.alxandr.me";
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

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
