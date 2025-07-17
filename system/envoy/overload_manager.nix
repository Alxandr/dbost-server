{
  refresh_interval = "0.25s";
  resource_monitors = [
    {
      name = "envoy.resource_monitors.fixed_heap";
      typed_config = {
        "@type" = "type.googleapis.com/envoy.extensions.resource_monitors.fixed_heap.v3.FixedHeapConfig";
        # TODO: Tune for your system.
        max_heap_size_bytes = 2147483648; # 2 GiB
      };
    }
  ];
  actions = [
    {
      name = "envoy.overload_actions.shrink_heap";
      triggers = [
        {
          name = "envoy.resource_monitors.fixed_heap";
          threshold = {
            value = 0.95;
          };
        }
      ];
    }
    {
      name = "envoy.overload_actions.stop_accepting_requests";
      triggers = [
        {
          name = "envoy.resource_monitors.fixed_heap";
          threshold = {
            value = 0.99;
          };
        }
      ];
    }
  ];
}
