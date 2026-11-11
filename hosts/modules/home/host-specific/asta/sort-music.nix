{ pkgs } : pkgs.writeShellApplication {
    name = "sort-music";

    runtimeInputs = with pkgs; [ coreutils ffmpeg gnused ];

    text = builtins.readFile ./sort-music.sh;
}
