{ config, lib, tailnet, ... } :
let
    haveSecrets = config.biggerworld.secrets.enable;
in {
    services.alloy.enable = haveSecrets;

    sops.secrets = lib.mkIf haveSecrets {
        loki-push-password = {
            sopsFile = ../../../../../secrets/secrets.yaml;
        };
    };

    systemd.services.alloy = lib.mkIf haveSecrets {
        after = [ "sops-nix.service" ];
        serviceConfig.LoadCredential =
            [ "loki-password:${config.sops.secrets.loki-push-password.path}" ];
    };

    environment.etc."alloy/journal.alloy" = lib.mkIf haveSecrets {
        text = ''
            discovery.relabel "journal" {
                targets = []

                rule {
                    source_labels = ["__journal__systemd_unit"]
                    target_label  = "unit"
                }

                rule {
                    source_labels = ["__journal__hostname"]
                    target_label  = "host"
                }
            }

            loki.source.journal "host" {
                max_age       = "12h"
                relabel_rules = discovery.relabel.journal.rules
                labels        = { job = "systemd-journal" }
                forward_to    = [loki.write.default.receiver]
            }

            loki.write "default" {
                endpoint {
                    url = "http://${tailnet.ips.loki}:3100/loki/api/v1/push"

                    basic_auth {
                        username      = "alloy"
                        password_file = "/run/credentials/alloy.service/loki-password"
                    }
                }
            }
        '';
    };
}
