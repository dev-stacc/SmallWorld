{ config, lib, pkgs, ... } : let
    cfg = config.biggerworld.serve;

    tailscale = "${pkgs.tailscale}/bin/tailscale";

    pathFlag = path:
        lib.optionalString (path != "/") " --set-path ${lib.escapeShellArg path}";

    nodeCommand = path: upstream:
        "${tailscale} serve --bg --https=443${pathFlag path} ${lib.escapeShellArg upstream}";

    serviceCommand = name: path: upstream:
        "${tailscale} serve --service=${lib.escapeShellArg "svc:${name}"}"
        + " --yes --bg --https=443${pathFlag path} ${lib.escapeShellArg upstream}";

    serviceCommands = lib.concatLists (lib.mapAttrsToList
        (name: routes: lib.mapAttrsToList (serviceCommand name) routes)
        cfg.services);

    commands = lib.mapAttrsToList nodeCommand cfg.node ++ serviceCommands;

    validName = name: builtins.match "[a-z0-9]([a-z0-9-]*[a-z0-9])?" name != null;
in {
    options.biggerworld.serve = {
        node = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            example = { "/" = "http://127.0.0.1:9847"; };
            description = ''
                Paths to expose over HTTPS on this node's own MagicDNS name via
                `tailscale serve`, mapped to the local upstream serving them.

                Tailscale issues certificates for `<host>.<tailnet>.ts.net` only,
                so these become `https://<host>.<tailnet>.ts.net<path>` - never an
                https:// URL on the raw 100.x tailnet IP.

                Additive: the upstream keeps whatever address it already binds, so
                existing plain-HTTP callers are unaffected.
            '';
        };

        services = lib.mkOption {
            type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
            default = { };
            example = { home = { "/" = "http://127.0.0.1:9847"; }; };
            description = ''
                Tailscale VIP services this node advertises, as service name ->
                path -> local upstream. Each becomes
                `https://<name>.<tailnet>.ts.net<path>`, a tailnet-level name that
                belongs to no machine, so the URL says what the thing is rather
                than which host happens to run it.

                Service and machine names share one namespace, so a name here must
                not collide with any device or with a service the Kubernetes
                operator already advertises.

                Advertising requires the tailnet policy to permit it, which is
                configured in the Tailscale admin console and is therefore not
                reproducible from this repository.
            '';
        };
    };

    config = lib.mkIf (commands != [ ]) {
        assertions = [{
            assertion = lib.all validName (lib.attrNames cfg.services);
            message = "biggerworld.serve.services names must be lowercase"
                + " alphanumeric with internal hyphens: "
                + lib.concatStringsSep " " (lib.filter (n: !validName n) (lib.attrNames cfg.services));
        }];

        systemd.services.tailscale-serve = {
            description = "Expose local services over HTTPS on the tailnet";
            after = [ "tailscaled.service" "network-online.target" ];
            wants = [ "network-online.target" ];
            requires = [ "tailscaled.service" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStartPre = "-${tailscale} serve reset";
                ExecStart = commands;
                Restart = "on-failure";
                RestartSec = 10;
            };
        };
    };
}
