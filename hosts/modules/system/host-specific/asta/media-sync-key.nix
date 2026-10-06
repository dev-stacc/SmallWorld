{ pkgs, username, ... } :
let
    guard = pkgs.writeShellScript "media-sync-guard" ''
        case "$SSH_ORIGINAL_COMMAND" in
            "rsync --server --sender "*" . /home/${username}/media/")
                exec $SSH_ORIGINAL_COMMAND
                ;;
        esac
        echo "only the media-sync rsync pull is permitted" >&2
        exit 1
    '';
in {
    users.users.${username}.openssh.authorizedKeys.keys = [
        ''restrict,command="${guard}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBSe0gcOazQdx5kC/90LYSkA/q5i2/H4oHOtPA2LK14x albireo-media-sync''
    ];
}
