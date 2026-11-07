{ config, lib, pkgs, username, ... } :
let
    dir = "/var/lib/argus-provision";

    reaper = pkgs.writeShellScript "argus-reap-authkey" ''
        set -u
        for i in $(seq 1 60); do
            state=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null \
                | ${pkgs.jq}/bin/jq -r '.BackendState // "none"')
            if [ "$state" = "Running" ]; then
                rm -f ${dir}/tailscale-authkey
                exit 0
            fi
            sleep 5
        done
        exit 0
    '';
in {
    options.biggerworld.provision.dir = lib.mkOption {
        type = lib.types.str;
        default = dir;
        readOnly = true;
        description = ''
            Where this host reads the credentials it cannot decrypt for itself.

            Argus holds no age key and is absent from .sops.yaml, so the usual
            sops path is unavailable: it is an off-site board on someone else's
            network and is assumed stealable. Its credentials are therefore
            written straight onto the SD card before first boot and never exist
            in the repository or the nix store.

            Expected contents, both mode 0600:
              tailscale-authkey  a single reusable auth key, no trailing newline
              pihole.env         FTLCONF_webserver_api_password=<the password>
              password-hash      a yescrypt hash from `mkpasswd -m yescrypt`

            The wifi passphrase is not here: iwd owns its own location, so it
            goes to /var/lib/iwd/<SSID>.psk in the same pass.

            Losing this board costs the wifi passphrase, the pihole admin
            password, and a tag:offsite identity, which grants nothing but DNS
            to aperture. It does not cost the fleet
            secret store.
        '';
    };

    config = {
        systemd.tmpfiles.rules = [
            "d ${dir} 0700 root root -"
            "d /var/lib/iwd 0700 root root -"
        ];

        services.tailscale.authKeyFile = "${dir}/tailscale-authkey";

        users.users.${username}.hashedPasswordFile = "${dir}/password-hash";

        systemd.services.argus-reap-authkey = {
            description = "Delete the tailnet auth key once the node has joined";
            after = [ "tailscaled-autoconnect.service" ];
            wants = [ "tailscaled-autoconnect.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = reaper;
            };
        };
    };
}
