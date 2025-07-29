{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib) getExe mkAfter;
  secrets = config.sops.secrets;
  secretPath = name: secrets.${name}.path;

  base-domain = "netbird.alxandr.me";
  turn-domain = "turn.${base-domain}";
  relay-domain = "relay.${base-domain}";

  relay-server = "${pkgs.netbird}/bin/netbird-relay";

in
{
  users.groups.netbird = { };
  users.users.netbird = {
    group = config.users.groups.netbird.name;
    isSystemUser = true;
  };

  security.acme.certs.${turn-domain} = {
    postRun = ''
      systemctl restart coturn.service
    '';
  };
  security.acme.certs.${relay-domain} = {
    postRun = ''
      systemctl restart netbird-relay.service
    '';
  };

  sops.secrets = {
    "netbird/coturn.password" = {
      sopsFile = ../../secrets/pangolin/netbird.yaml;
      format = "yaml";
      key = "coturn/password";
      owner = config.users.users.turnserver.name;
      group = config.users.users.turnserver.group;
      mode = "0440";
      restartUnits = [ "coturn" ];
    };
    "netbird/relay.env" = {
      sopsFile = ../../secrets/pangolin/netbird.yaml;
      format = "yaml";
      key = "relay/env";
      owner = config.users.users.netbird.name;
      group = config.users.users.netbird.group;
      mode = "0440";
      restartUnits = [ "netbird-relay" ];
    };
  };

  services.coturn = {
    enable = true;

    realm = turn-domain;
    lt-cred-mech = true;
    no-cli = true;

    cert = "@cert@";
    pkey = "@pkey@";

    extraConfig = ''
      fingerprint
      user=netbird:@password@
      no-software-attribute
      log-file=stdout
    '';
  };

  systemd.services.coturn =
    let
      dir = config.security.acme.certs.${turn-domain}.directory;
      preStart' = ''
        ${getExe pkgs.replace-secret} @password@ ${secretPath "netbird/coturn.password"} /run/coturn/turnserver.cfg
        ${getExe pkgs.replace-secret} @cert@ <(echo -n "$CREDENTIALS_DIRECTORY/cert.pem") /run/coturn/turnserver.cfg
        ${getExe pkgs.replace-secret} @pkey@ <(echo -n "$CREDENTIALS_DIRECTORY/pkey.pem") /run/coturn/turnserver.cfg
      '';
    in
    {
      preStart = mkAfter preStart';
      serviceConfig.LoadCredential = [
        "cert.pem:${dir}/fullchain.pem"
        "pkey.pem:${dir}/key.pem"
      ];
    };

  systemd.services.netbird-relay =
    let
      dir = config.security.acme.certs.${relay-domain}.directory;
    in
    {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Netbird Relay Service";

      serviceConfig = {
        Type = "simple";
        User = "netbird";
        Group = "netbird";

        ExecStart = ''${relay-server} --log-file console --metrics-port 9090 --tls-cert-file "$CREDENTIALS_DIRECTORY/cert.pem" --tls-key-file "$CREDENTIALS_DIRECTORY/pkey.pem"'';
        Environment = [
          "NB_LOG_LEVEL=info"
          "NB_LISTEN_ADDRESS=:33080"
          "NB_EXPOSED_ADDRESS=rels://relay.netbird.alxandr.me/relay"
        ];
        EnvironmentFile = [
          (secretPath "netbird/relay.env")
        ];
        LoadCredential = [
          "cert.pem:${dir}/fullchain.pem"
          "pkey.pem:${dir}/key.pem"
        ];
      };
    };

  networking.firewall =
    let
      openPorts = with config.services.coturn; [
        listening-port
        alt-listening-port
        tls-listening-port
        alt-tls-listening-port
      ];
    in
    {
      allowedUDPPorts = openPorts;
      allowedTCPPorts = openPorts;

      allowedUDPPortRanges = with config.services.coturn; [
        {
          from = min-port;
          to = max-port;
        }
      ];
    };
}
