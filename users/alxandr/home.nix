{ pkgs, lib, ... }:

let
  sharedShell = [
    ''
      # Load shared functions
      . ${./functions.sh}
    ''
  ];

in

{
  programs.home-manager.enable = true;

  programs.zoxide.enable = true;
  programs.starship.enable = true;
  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.eza.enable = true;

  home.packages = with pkgs; [
    dua
  ];

  home.shellAliases = {
    # Add color to commands
    grep = "grep --color=auto";

    # Protect against overwriting
    cp = "cp -i";
    mv = "mv -i";

    # cd to git root directory
    cdg = "cd \"$(git root)\"";

    # Mirror stdout to stderr, useful for seeing data going through a pipe
    peek = "tee >(cat 1>&2)";

    # Bat
    cat = "bat --style=plain --paging=never";
    catmore = "bat --style=plain --paging=always";

    # eza
    ls = "eza";
    ll = "eza -lh";
    tree = "eza --tree";

    # zoxide
    zz = "z -";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.size = 10000;

    initContent = lib.strings.concatLines sharedShell;
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;

    initExtra = lib.strings.concatLines sharedShell;
  };

  # This value determines the home-manager release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option.
  home.stateVersion = "25.05"; # Did you read the comment?
}
