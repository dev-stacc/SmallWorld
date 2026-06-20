# Placeholder. Regenerate on argus during Stage A install with:
#   nixos-generate-config --no-filesystems --root /mnt
# then copy /mnt/etc/nixos/hardware-configuration.nix here, plus add fileSystems
# entries by hand (BIOS install, single ext4 root on /dev/sda1, no /boot).
{ ... }: {
    imports = [ ];
}
