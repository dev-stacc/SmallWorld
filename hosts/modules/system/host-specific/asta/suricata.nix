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
    ];
    settings = {
      "af-packet" = [{
        interface = "tailscale0";
        "cluster-id" = 99;
        "cluster-type" = "cluster_flow";
        defrag = true;
      }];
      "app-layer".protocols.modbus = {
        enabled = "yes";
        "detection-enabled" = "yes";
        "stream-depth" = 0;
      };

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
  systemd.timers.suricata-update.wantedBy = [ "timers.target" ];
}
