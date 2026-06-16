# BiggerWorld

My personal homelab: a NixOS + k3s cluster built from spare hardware while teaching myself what infrastructure actually looks like under the hood. Every host is declared in this flake, every cluster workload is delivered by Flux, every secret is encrypted with SOPS, and every service is reachable only inside my Tailscale tailnet.

This is also a CV piece, so to be upfront: I'm an early-career engineer. The commit history has the bumps to prove the learning was real.

## Hosts

| Host      | Hardware                              | Role                                                                  |
|-----------|---------------------------------------|-----------------------------------------------------------------------|
| Arcturus  | ThinkPad, Intel iGPU                  | Daily driver. Hyprland desktop. k3s control client (kubeconfig from SOPS) |
| Asta      | Primary server                        | k3s server, media (Jellyfin, Navidrome), Vault, Flux source-of-truth  |
| Aperture  | OptiPlex 3020, headless               | k3s agent                                                             |
| Amateus   | ThinkPad SL500, headless              | NFS server backing cluster `PersistentVolume`s                        |
| Antinoos  | Desktop, i5 6th gen + AMD RX 580      | Sway desktop driving 4K@60 over Polaris                               |

All hosts join via Tailscale. Ingress is tailnet-only. No public DNS, no port-forwarding for now.


## Host stories

Every machine here has a history

**Arcturus** A ThinkPad E490 (i5 8th gen, Intel iGPU). Bought 2018-19 for the CÉGEP with Windows 10 that auto-promoted itself to 11. The 4 GB Windows baseline made IDEs crawl, so I switched to Linux Mint, then Arch (dependency-conflict hell, dotfile sprawl), then NixOS. Since then: 32 GB RAM, new battery, and a two-heatpipe heatsink swap I had to do twice because the first Amazon seller shipped an E480 part claiming it fit and I found one on Alibaba that actually fit. Stock E490s idles at 50-65 °C, this one stays under 40, and the workflow usually fits in 3 GB so the 32 is overkill in the best way.

**Asta** a Stripped-down Toshiba Satellite L-855 (socketed AMD A8/A10, ~10+ years old) my brother handed down. I tore off the shell and standoffed the motherboard onto a serving tray with the HDD, RAM, and heatsink. At that point it was literally going to serve things. 16 GB DDR3 upgrade done, CPU swap planned. First node in the cluster.

**Amateus** A refurbished ThinkPad SL500 from eBay, missing a few keys but the seller was honest about it. Cleaned, repasted, +2 GB DDR2. Keyboard fels great even with the gaps. Used to be the k3s agent. Eventual plan is a modern-internals mod in the spirit of the X210AI project (modern CPU, DDR5, NVMe inside the vintage chassis).

**Aperture** A refurbished Dell OptiPlex 3020 from eBay, $80. i5 4th gen, 12 GB DDR3, SSD + HDD, dedicated GPU. Light dust, fresh paste, NixOS, `git pull`, done - fastest a host has ever joined this cluster. Original case kept. It's now the k3s agent, taking over the role Amateus used to fill.

**Antinoos** Less linear. Motherboard came from a retired Acer Aspire of my mom's (i5 6th gen, 16 GB DDR3, 3 TB storage). I wanted a light-gaming desktop because the console subscription model is going to be more expensive than this over time. First RX 580 was a defective eBay refurb that mostly worked, then didn't - probably ex-mining. Replaced with a sealed, tested RX 580 and a new Corsair PSU; mounted on a serving tray like Asta for airflow. Might become a cluster node next time I rebuild a desktop.

### Honourable mention

**Sanctuary** A Raspberry Pi Zero 2 W running Pi-hole + unbound on Raspberry Pi OS. Not part of this flake (16 GB of storage rules NixOS out for now), but it's where this whole homelab started. The orbital-sync CronJobs in `k8s/apps/pihole/orbital-sync.yaml` keep this Pi and the cluster's Pi-hole mirroring each other.

---
## Stack

- **NixOS** flakes for every host config; **home-manager** as a NixOS module
- **colmena** for remote deploys
- **k3s** (1 server, 1 agent) on the tailnet (`--flannel-iface=tailscale0`)
- **Flux** for GitOps with SOPS decryption + `postBuild.substituteFrom` for cluster-wide variables
- **SOPS + age** for declarative secrets, plus **Vault** + **external-secrets-operator** for runtime secrets
- **Authentik** for SSO across self-hosted services
- **CrowdSec** with a Pi-hole bouncer (Suricata deferred - Helm chart schema issue)
- **stylix** for system-wide theming, **nixvim** for declarative Neovim

## Repo layout

```
flake.nix              # Hosts, colmena, specialArgs (username + tailnet)
hosts/<name>/          # Per-host entry, hardware-configuration, home-manager binding
modules/system/        # NixOS modules - common, server-specific, host-specific
modules/home/          # home-manager modules - common, host-specific
secrets/secrets.yaml   # SOPS-encrypted secrets shared across all five hosts
k8s/flux/              # Flux bootstrap + cluster-config ConfigMap
k8s/apps/              # Workload Kustomizations
k8s/apps-config/       # Post-deploy configs (Authentik blueprints, etc.)
mobiles/               # Android debloat scripts for personal devices
```

## How configuration flows

`flake.nix` defines `username` and a `tailnet` attrset (domain + per-host IPs), then threads them into every NixOS module via `specialArgs` and into every home-manager module via `extraSpecialArgs`. Renaming the user or moving the tailnet is a single-line edit.

On the cluster side, both Flux `Kustomization`s use `postBuild.substituteFrom` against a `cluster-config` ConfigMap, so the same network and path values that drive Nix configs also drive ingress hosts and `hostPath` volumes. Shell `${VAR}` references in container scripts are escaped as `$${VAR}` so Flux passes them through.

## Deploy

```sh
sudo nixos-rebuild switch --flake .#<HostName>   # locally on a host
colmena apply                                    # remote deploy of all hosts
```

## Things worth a read

- `modules/system/host-specific/antinoos/sway.nix` - started this host on Hyprland, hit `eglDupNativeFenceFDANDROID EGL_BAD_PARAMETER` crashes on Polaris that `AQ_NO_ATOMIC=1` + `AQ_NO_MODIFIERS=1` + disabled explicit-sync couldn't fully fix. Switched to Sway with `WLR_DRM_NO_ATOMIC=1` + `WLR_NO_HARDWARE_CURSORS=1` and the panel finally stayed up at 4K@60.
- `modules/system/host-specific/arcturus/k3s-kubeconfig.nix` - `~/.kube/config` is a `mkOutOfStoreSymlink` to a SOPS-decrypted kubeconfig, so admin cluster credentials are declarative without ending up in the Nix store.
- `k8s/flux/flux-system/cluster-config.yaml` - the single ConfigMap every workload substitutes against.
- `modules/system/host-specific/asta/vault.nix` - Vault unseal driven by SOPS, ordered against `sops-nix.service` so it survives reboots.
- `mobiles/` - bonus: ADB-driven debloat for a Samsung Galaxy A16 5G (40+ packages removed, Knox left alone).

---
Learning project. Issues and corrections are welcome.
