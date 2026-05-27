{ config, pkgs, ... } : {
    programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        gamescopeSession.enable = true;
        localNetworkGameTransfers.openFirewall = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    programs.gamemode.enable = true;
    
    environment.systemPackages = with pkgs; [
        mangohud
        protonup-qt
        vulkan-tools
    ];
}
