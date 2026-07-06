# BiggerWorld

My personal homelab: a NixOS + k3s cluster built from spare hardware while teaching myself what infrastructure actually looks like under the hood. Every host is declared in this flake, every cluster workload is delivered by Flux, every secret is encrypted with SOPS, and every service is reachable only inside my Tailscale tailnet.

This doubles as a CV piece. Built solo while teaching myself the stack.

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
flake.nix                       Hosts, colmena, specialArgs (username + tailnet)

hosts/                          Per-host entrypoints
├── arcturus/                   hardware-configuration + home-manager binding
├── antinoos/                   (one folder per host, same shape)
├── aperture/
├── amateus/
├── argus/
└── asta/

modules/
├── system/                     NixOS modules
│   ├── common/
│   │   ├── all/                Applied to every host
│   │   ├── admin/              Heavy CLI tools (kubectl, helm, flux, vault, colmena) - arcturus only
│   │   ├── desktops/           Shared by desktop hosts (arcturus, antinoos)
│   │   └── servers/            Shared by server hosts (asta, aperture, amateus, argus)
│   └── host-specific/          Per-host overrides (graphics, sway, vault, k3s, pi-hole, ...)
└── home/                       home-manager modules (mirrors the system/ layout)
    ├── common/
    │   ├── all/                Shell, git, ssh, terminal
    │   └── desktops/           Waybar (shared), nixvim, qutebrowser, fonts
    └── host-specific/          WM configs, host-specific waybar (GPU vs CPU thermals)

secrets/
└── secrets.yaml                SOPS-encrypted, shared across all five hosts

k8s/
├── flux/
│   └── flux-system/            Flux bootstrap + cluster-config ConfigMap
├── apps/                       Workload Kustomizations (one folder per app)
│   ├── crowdsec/               IDS (Pi-hole bouncer now lives on argus as a systemd service)
│   ├── external-secrets/       Vault-backed runtime secrets
│   ├── ingress-nginx/
│   ├── jellyfin/               Media (video)
│   ├── monitoring/             Grafana stack
│   ├── navidrome/              Media (music)
│   ├── nfs-provisioner/        PVs backed by amateus
│   ├── tailscale/
│   ├── uptime-kuma/
│   ├── vault/
│   ├── marketing-tool/         Version of an app I built during my internship at Enjoy Social
│   └── sewing-assistant/       Full-stack personal project to track my sewing projects
└── apps-config/                Post-deploy configs
    ├── authentik/              SSO blueprints
    ├── crowdsec/
    ├── external-secrets/
    └── grafana/

mobiles/                        Android debloat scripts for personal devices
├── devices/                    Per-device package lists
├── modules/                    Reusable debloat actions (apps, config, debloat)
└── lib/
```

## Hosts

| Host      | Hardware                                                          | Role                                                                       |
|-----------|-------------------------------------------------------------------|----------------------------------------------------------------------------|
| Arcturus  | ThinkPad E490, i5 8th gen, 32 GB DDR4, Intel iGPU                 | Daily driver. Hyprland desktop. k3s control client (kubeconfig from SOPS). |
| Asta      | Toshiba Satellite L-855 board, AMD A8/A10, 16 GB DDR3, tray-mount | k3s server, media (Jellyfin, Navidrome), Vault, Flux source-of-truth. Headless. |
| Aperture  | Dell OptiPlex 3020, i5 4th gen, 12 GB DDR3, SSD + HDD, dGPU       | k3s agent. Headless.                                                       |
| Amateus   | ThinkPad SL500 (refurb), Core 2 Duo, DDR2                         | NFS server backing cluster `PersistentVolume`s. Headless.                  |
| Antinoos  | Acer Aspire board, i5 6th gen, 16 GB DDR3, 3 TB storage, RX 580   | Sway desktop driving 4K@60 over Polaris.                                   |
| Argus     | Acer Aspire laptop, i3-380m (2C/4T, ~2010), 8 GB DDR3, BIOS       | Pi-hole + unbound. Tailnet DNS sentinel. Headless.                         |

All hosts join via Tailscale. Ingress is tailnet-only. No public DNS, no port-forwarding for now.

## Host stories

<details>
<summary>The history behind each machine (click to expand)</summary>

Every machine here has a history.

**Arcturus** A ThinkPad E490 (i5 8th gen, Intel iGPU). Bought 2018-19 for the CÉGEP with Windows 10 that auto-promoted itself to 11. The 4 GB Windows baseline made IDEs crawl, so I switched to Linux Mint, then Arch (dependency-conflict hell, dotfile sprawl), then NixOS. Since then: 32 GB RAM, new battery, and a two-heatpipe heatsink swap I had to do twice because the first Amazon seller shipped an E480 part claiming it fit and I found one on Alibaba that actually fit. Stock E490s idles at 50-65 °C, this one usually stays around 40, and the workflow usually fits in 3 GB so the 32 is overkill in the best way.

**Asta** A stripped-down Toshiba Satellite L-855 (socketed AMD A8/A10, ~10+ years old) my brother handed down. I tore off the shell and standoffed the motherboard onto a serving tray with the HDD, RAM, and heatsink. At that point it was literally going to serve things. 16 GB DDR3 upgrade done, CPU swap planned. First node in the cluster.

**Amateus** A refurbished ThinkPad SL500 from eBay, missing a few keys but the seller was honest about it. Cleaned, repasted, +2 GB DDR2. Keyboard feels great even with the gaps. Used to be the k3s agent. Eventual plan is a modern-internals mod in the spirit of the X210AI project (modern CPU, DDR5, NVMe inside the vintage chassis).

**Aperture** A refurbished Dell OptiPlex 3020 from eBay, $80. i5 4th gen, 12 GB DDR3, SSD + HDD, dedicated GPU. Light dust, fresh paste, NixOS, `git pull`, done - fastest a host has ever joined this cluster. Original case kept. It's now the k3s agent, taking over the role Amateus used to fill.

**Antinoos** Less linear. Motherboard came from a retired Acer Aspire of my mom's (i5 6th gen, 16 GB DDR3, 3 TB storage). I wanted a light-gaming desktop because the console subscription model is going to be more expensive than this over time. First RX 580 was a defective eBay refurb that mostly worked, then didn't - probably ex-mining. Replaced with a sealed, tested RX 580 and a new Corsair PSU; mounted on a serving tray like Asta for airflow. Might become a cluster node next time I rebuild a desktop.

**Argus** Another hand-me-down: some i3-380m laptop, ~2010 vintage. The screen and keyboard were broken. Cleaned, repasted, and wiped the HDD. Getting into the BIOS to change the boot order was its own little battle. eventual plan is to strip it down to the motherboard in the spirit of Asta and Antinoos.

### Honourable mention

**Sanctuary** A Raspberry Pi Zero 2 W running Pi-hole + unbound on Raspberry Pi OS. Not part of this flake (16 GB of storage rules NixOS out for now), but it's where this whole homelab started. The orbital-sync systemd timers in `modules/system/host-specific/argus/pihole-sync.nix` keep this Pi and Argus's Pi-hole mirroring each other.

</details>

---

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

## What I'd do differently

- Module structure from day one. I started by copying patterns I saw in other repos. That worked at one or two hosts but got hard to navigate at five. With 3+ hosts planned, I'd go straight to the current `modules/{system,home}/{common,host-specific}` split instead of refactoring my way into it.
- Authentik before the apps. I deployed Jellyfin and Navidrome first and had to refactor both substantially once Authentik landed and they needed SSO wiring. Next time the auth layer goes up first, and every app is wired into it from the start.
- Branches, PRs, and code review. I worked mostly on `main` because this started as a personal project; the cost is a noisy log and no review trail. Even solo, a branch + PR flow forces a moment of "is this the change I actually want," and another pair of eyes catches what self-review misses.
- More research before coding. Solo work on my own hardware made me unafraid to break things, which is great for momentum and bad for measuring twice.

## Future / ongoing

- A "Wrapped"-style web app for AO3 reading history (currently in progress).
- Ongoing tuning of the `mobiles/` debloat scripts. Still iterating on what to keep vs drop so the phone has the functionality I need without reintroducing the weight.
- Cluster nodes in more physical locations so power outages don't take everything down at once. UPS coverage helps but doesn't outlive a long outage. Targeting December 2026.
- A physical-media ripper of my own, instead of relying on an existing package, for the CDs, DVDs, and Blu-rays I own. Targeting summer 2026.
- A sync app that pulls my music library into Navidrome automatically. Targeting autumn 2026.

---
Feedback and corrections welcome!
