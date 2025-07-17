[
  {
    name = "service_headscale";
    per_connection_buffer_limit_bytes = 32768; # 32 KiB
    load_assignment = {
      cluster_name = "service_headscale";
      endpoints = [
        {
          lb_endpoints = [
            {
              endpoint.address.socket_address = {
                address = "127.0.0.1";
                port_value = 8080; # Headscale gRPC port
              };
            }
          ];
        }
      ];
      typed_extension_protocol_options."envoy.extensions.upstreams.http.v3.HttpProtocolOptions" = {
        "@type" = "type.googleapis.com/envoy.extensions.upstreams.http.v3.HttpProtocolOptions";
        explicit_http_config.http2_protocol_options = {
          initial_stream_window_size = 65536; # 64 KiB
          initial_connection_window_size = 1048576; # 1 MiB
        };
      };
    };
  }
]
