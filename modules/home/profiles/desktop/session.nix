{ pkgs, ... } : let
    lockoutScript = pkgs.writeShellScript "lockout" (builtins.readFile ./scripts/lockout.sh);
    detachScript = pkgs.writeShellScript "detach" (builtins.readFile ./scripts/detach.sh);
in {
    home.file = {
        ".local/bin/lockout" = {
            source = lockoutScript;
            executable = true;
        };
        ".local/bin/detach" = {
            source = detachScript;
            executable = true;
        };
    };
}
