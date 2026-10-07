{ tailnet, ... } : {
    services.alloy.enable = true;

    environment.etc."alloy/journal.alloy".text = ''
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
            }
        }
    '';
}
