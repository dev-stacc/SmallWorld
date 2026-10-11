{ config, lib, pkgs, ... } : let
    cfg = config.biggerworld.serve;

    mapping = path: upstream:
        let
            pathFlag = lib.optionalString (path != "/") " --set-path ${lib.escapeShellArg path}";
        in
        "${pkgs.tailscale}/bin/tailscale serve --bg --https=443${pathFlag} ${lib.escapeShellArg upstream}";
in {
    options.biggerworld.serve = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = { "/" = "http://127.0.0.1:9847"; };
        description = ''
            Paths to expose over HTTPS on this node's MagicDNS name via
            `tailscale serve`, mapped to the local upstream serving them.

            Tailscale issues certificates for `<host>.<tailnet>.ts.net` only, so
            these become `https://<host>.<tailnet>.ts.net<path>` - never an
            https:// URL on the raw 100.x tailnet IP.

            Additive: the upstream keeps whatever address it already binds, so
            existing plain-HTTP callers are unaffected.
        '';
    };

    config = lib.mkIf (cfg != { }) {
        systemd.services.tailscale-serve = {
            description = "Expose local services over HTTPS on the tailnet";
            after = [ "tailscaled.service" "network-online.target" ];
            wants = [ "network-online.target" ];
            requires = [ "tailscaled.service" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStartPre = "-${pkgs.tailscale}/bin/tailscale serve reset";
                ExecStart = lib.mapAttrsToList mapping cfg;
                Restart = "on-failure";
                RestartSec = 10;
            };
        };
    };
}
