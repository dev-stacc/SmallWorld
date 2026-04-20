{ config, pkgs, ... } : {
    fonts = {
        fontconfig.enable = true;
        
        packages = with pkgs; [
            departure-mono
        ];
        };
        
    environment.etc."fonts/conf.d/100-nix-user-fonts.conf".text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <dir>/run/current-system/sw/share/fonts</dir>
        </fontconfig>
    '';
}