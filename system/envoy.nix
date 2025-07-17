{

  admin = import ./envoy/admin.nix;
  overload_manager = import ./envoy/overload_manager.nix;
  layered_runtime = import ./envoy/layered_runtime.nix;

  static_resources = {
    clusters = import ./envoy/clusters.nix;

    listeners = [
      {
        name = "http";
        address = {
          socket_address = {
            address = "0.0.0.0";
            port_value = 80;
          };
        };
        filter_chains = [
          {
            filters = [
              {
                name = "envoy.filters.network.http_connection_manager";
                typed_config = {
                  "@type" =
                    "type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager";
                  stat_prefix = "ingress_http";
                  use_remote_address = true; # Ignore X-Forwarded-For
                  normalize_path = true;
                  merge_slashes = true;
                  path_with_escaped_slashes_action = "UNESCAPE_AND_REDIRECT";
                  common_http_protocol_options = {
                    idle_timeout = "3600s"; # 1 hour
                    headers_with_underscores_action = "REJECT_REQUEST";
                  };
                  http2_protocol_options = {
                    max_concurrent_streams = 100;
                    initial_stream_window_size = 65536; # 64 KiB
                    initial_connection_window_size = 1048576; # 1 MiB
                  };
                  stream_idle_timeout = "300s"; # 5 minutes, must be disabled for long-lived and streaming requests
                  request_timeout = "300s"; # 5 minutes, must be disabled for long-lived and streaming requests
                  route_config = {
                    name = "http_route";
                    virtual_hosts = [
                      {
                        name = "backend";
                        domains = [ "*" ];
                        routes = [
                          {
                            match.prefix = "/";
                            redirect.https_redirect = true; # Redirect HTTP to HTTPS
                          }
                        ];
                      }
                    ];
                  };
                  http_filters = [
                    {
                      name = "envoy.filters.http.router";
                      typed_config."@type" = "type.googleapis.com/envoy.extensions.filters.http.router.v3.Router";
                    }
                  ];
                };
              }
            ];
          }
        ];
      }
    ];

  };
}
