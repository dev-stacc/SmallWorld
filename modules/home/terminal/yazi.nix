{ config, lib, pkgs, ... } : {
    home.packages = with pkgs; [
        bat
        ffmpegthumbnailer
        unar
        jq
        poppler
        fd
        ripgrep
    ];

    programs.yazi = {
        enable = true;
        enableBashIntegration = true;
        shellWrapperName = "y";
        package = pkgs.yazi;

        settings = {
            mgr = {
                sort_by = "natural";
                sort_sensitive = false;
                sort_reverse = false;
                sort_dir_first = true;
                sort_translite = false;
                linemode = "btime";
                show_hidden = true;
                show_symlink = true;
            };

            preview = {
                tab_size = 2;
                max_width = 1920;
                max_height = 1080;
                image_filter = "lanczos3";
                image_quality = 75;
            };

            opener = {
                edit = [
                    { run = "nvim \"$@\""; block = true ;}
                ];
                open = [
                    { run = "xdg-open \"$@\""; }
                ];
                play = [
                    { run = "mpv \"$@\""; orphan = true; }
                ];
                extract = [
                    { run = "unar \"$1\""; }
                ];
            };

            open = {
                rules = [
                    {
                        name = "*/";
                        use = [ "edit" "open" ];
                    }
                    { 
                        mime = "text/*";
                        use = [ "edit" "open" ];
                    }
                    {
                        mime = "image/*";
                        use = [ "open" ];
                    }
                    {
                        mime = "video/*";
                        use = [ "play" "open" ];
                    }
                    {
                        mime = "audio/*";
                        use = [ "play" ];
                    }
                    {
                        mime = "application/zip";
                        use = [ "extract" "open" ];
                    }
                    {
                        mime = "application/gzip";
                        use = [ "extract" "open" ];
                    }
                    {
                        mime = "*";
                        use = [ "open" "edit" ];
                    }
                ];
            };
        };
        
        keymap = {
            manager.prepend_keymap = [
                { 
                    on = [ "." ];
                    run = "hidden toggle";
                    desc = "Toggle hidden files";
                }
                { 
                    on = [ "e" ];
                    run = "open --interactive";
                    desc = "Open"; 
                }
                { 
                    on = [ "h" ];
                    run = "leave";
                    desc = "Go to parent dir";
                }
                {
                    on = [ "l" ];
                    run = "open";
                    desc = "Open / enter dir";
                }
            ];
        };
    };
}
