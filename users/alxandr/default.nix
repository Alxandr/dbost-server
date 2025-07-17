{
  trusted = true;

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPyTEFPeilMh1fmKwEo50X50Bha5UCO68pG7LylTcUtE alxandr@alxandr.me"
  ];

  user.extraGroups = [
    "wheel"
    "keys"
  ];

  home = ./home.nix;
}
