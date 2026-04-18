{ config, lib, ... } : {
    window = lib.mkForce {
         transparent = true;
         hide_decoration = true;
    };
}