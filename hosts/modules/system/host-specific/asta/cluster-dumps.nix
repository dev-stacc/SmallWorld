{ pkgs, ... } :
let
    db = "/var/lib/rancher/k3s/server/db/state.db";
    out = "/var/lib/cluster-dumps/k3s/state.db";

    snapshot = pkgs.writeShellScript "k3s-datastore-snapshot" ''
        set -eu

        if [ ! -f ${db} ]; then
            echo "no sqlite datastore at ${db}, skipping"
            exit 0
        fi

        ${pkgs.sqlite}/bin/sqlite3 ${db} ".backup '${out}.tmp'"
        mv ${out}.tmp ${out}
        echo "wrote ${out} ($(${pkgs.coreutils}/bin/stat -c %s ${out}) bytes)"
    '';
in {
    services.restic.backups.cluster.backupPrepareCommand = "${snapshot}";
}
