{
  layers = [
    {
      name = "static_layer_0";
      static_layer.envoy.resource_limits.listener.example_listener_name.connection_limit = 10000;
      static_layer.overload.global_downstream_max_connections = 50000;
    }
  ];
}
