{ config, pkgs, ... }: {
  services.suricata = {
    enable = true;
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
}
