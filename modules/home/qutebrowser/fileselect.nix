{ ... }: {
    content.fileselect = {
        handler = "external";
        single_file.command = [ "kitty" "-e" "yazi" "--chooser-file={}" ];
        multiple_files.command = [ "kitty" "-e" "yazi" "--chooser-file={}" ];
        folder.command = [ "kitty" "-e" "yazi" "--chooser-file={}" ];
    };
}
