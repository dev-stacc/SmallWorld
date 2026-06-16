{ config, ... } : {
    boot.extraModulePackages = [ config.boot.kernelPackages.it87 ];
    boot.kernelModules = [ "it87" ];
    boot.extraModprobeConfig = ''
        options it87 force_id=0x8613 ignore_resource_conflict=1
    '';
}
