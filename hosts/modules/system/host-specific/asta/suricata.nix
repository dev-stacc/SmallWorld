{ ... }: {
  services.suricata = {
    enable = true;
    enabledSources = [
      "abuse.ch/sslbl-blacklist"
      "abuse.ch/sslbl-ja3"
      "et/open"
      "etnetera/aggressive"
      "stamus/lateral"
      "oisf/trafficid"
      "tgreen/hunting"
      "pawpatrules"
      "ptrules/open"
    ];
    settings = {
      "af-packet" = [{
        interface = "tailscale0";
        "cluster-id" = 99;
        "cluster-type" = "cluster_flow";
        defrag = true;
      }];
      outputs = [{
        "eve-log" = {
          enabled = true;
          filetype = "regular";
          filename = "eve.json";
          types = [
            { alert = {}; }
            { http = { extended = true; }; }
            { dns = {}; }
            { tls = { extended = true; }; }
            { flow = {}; }
          ];
        };
      }];
    };
  };

  systemd.services.suricata-update.restartIfChanged = false;
}
