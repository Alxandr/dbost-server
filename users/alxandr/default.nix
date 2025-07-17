{
  trusted = true;

  user.extraGroups = [
    "wheel"
    "keys"
  ];

  home = ./home.nix;
}
