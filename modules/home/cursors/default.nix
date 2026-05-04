#got the cursors from elfantasmaponi on deviantart
#https://www.deviantart.com/elfantasmaponi/gallery
{ pkgs, ... }:
let
  cyberpunk-cursors = pkgs.runCommand "cyberpunk2077-cursors" {} ''
    mkdir -p $out/share/icons/Cyberpunk2077
    cp -r ${./cyberpunk2077}/* $out/share/icons/Cyberpunk2077/
  '';
in {
  home.pointerCursor = {
    package = cyberpunk-cursors;
    name = "Cyberpunk2077";
    size = 12;
    gtk.enable = true;
    x11.enable = true;
  };
}
