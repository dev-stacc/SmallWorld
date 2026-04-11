{...}:
let
 palette = import ./palette.nix;
 #cockpit = import ./wallpapers/cockpit.mp4;
in
{
 wayland.windowManager.hyprland = {
  enable = true;
  settings = {
   "$mod" = "SUPER";
   bind = [
    "$mod,Return,exec,kitty"
    "$mod,D,exec,(pkill kitty-launcher && pkill kitty-control) || kitty --title kitty-launcher -e ~/.local/bin/kitty-launcher"
    "$mod,N,exec,(pkill kitty-control && pkill kitty-launcher) || kitty --title kitty-control -e ~/.local/bin/kitty-control" 
    "$mod SHIFT,C,exec,hyprctl reload"
    "$mod,M,exit,Hyprland"
    "$mod,Q,killactive"
    "$mod,F,fullscreen"
    "$mod,left,movefocus,l"
    "$mod,right,movefocus,r"
    "$mod,up,movefocus,u"
    "$mod,down,movefocus,d"
    "$mod SHIFT,left,movewindow,l"
    "$mod SHIFT,right,movewindow,r"
    "$mod SHIFT,up,movewindow,u"
    "$mod SHIFT,down,movewindow,d"
    "$mod,1,workspace,1"
    "$mod,2,workspace,2"
    "$mod,3,workspace,3"
    "$mod,4,workspace,4"
    "$mod,5,workspace,5"
    "$mod,6,workspace,6"
    "$mod SHIFT,1,movetoworkspace,1"
    "$mod SHIFT,2,movetoworkspace,2"
    "$mod SHIFT,3,movetoworkspace,3"
    "$mod SHIFT,4,movetoworkspace,4"
    "$mod SHIFT,5,movetoworkspace,5"
    "$mod SHIFT,6,movetoworkspace,6"
    ",XF86AudioMute,exec,wpctl set-mute @DEFAULT_SINK@ toggle"
    ",XF86AudioLowerVolume,exec,wpctl set-volume -l 1.0 @DEFAULT_SINK@ 5%-"
    ",XF86AudioRaiseVolume,exec,wpctl set-volume -l 1.0 @DEFAULT_SINK@ 5%+"
    ",XF86AudioMicMute,exec,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
    ",XF86MonBrightnessDown,exec,brightnessctl --device=intel_backlight set 5%-"
    ",XF86MonBrightnessUp,exec,brightnessctl  --device=intel_backlight set +5%"
    ",Print,exec,hyprshot -m output -m active"
    "SHIFT,Print,exec,hyprshot -m region"
    "CTRL,Print,exec,hyprshot -m window -m active"
   ];
   general = {
    gaps_in = 6;
    gaps_out = 9;
    border_size = 1;
    #"col.active_border" = "rgb(${palette.accent})";
    #"col.inactive_border" = "rgb(${palette.bg})";
    #"col.nogroup_border" = "rgb(${palette.bg})";
    #"col.nogroup_border_active" = "rgb(${palette.accent})";
    locale = "en_CA";
    layout = "master";
   };

   decoration = {
    rounding = 24;
    rounding_power = 1.0;
    active_opacity = 0.9;
    inactive_opacity = 0.6;
    dim_inactive = true;
    dim_strength = 0.6;
    
    blur = {
     enabled = true;
     size = 3;
     passes = 2;
     ignore_opacity = false;
    };

    shadow = {
     enabled = true;
     range = 9;
     #color = "rgb(${palette.lighter_bg})";
     #color_inactive = "rgb(${palette.bg})";
    };
   };

   input = {
    kb_layout = "ca";
    kb_variant = "fr";
   };

   windowrule = [
    "match:title kitty-launcher, float yes, center yes, dim_around yes, size 420 195, no_anim yes"
    "match:title kitty-control, float yes, center yes, dim_around yes, size 420 195, no_anim yes"
   ];

   monitorv2 = {
    output = "eDP-1";
    mode = "1920x1080@30";
    position = "0x0";
    scale = 1;
   };
  };
 };
}
