# BiggerWorld

My personal homelab: a NixOS + k3s cluster built from spare hardware while teaching myself what infrastructure actually looks like under the hood. Every host is declared in this flake, every cluster workload is delivered by Flux, every secret is encrypted with SOPS, and every service is reachable only inside my Tailscale tailnet.

## Stack

- **NixOS** flakes for every host config; **home-manager** as a NixOS module
- **colmena** for remote deploys
- **k3s** (1 server, 3 agent roles - Avior pending install) on the tailnet; flannel rides the LAN NICs with `--flannel-backend=wireguard-native`
- **Flux** for GitOps with SOPS decryption + `postBuild.substituteFrom` for cluster-wide variables
- **SOPS + age** for declarative secrets, plus **Vault** + **external-secrets-operator** for runtime secrets
- **Authentik** for SSO across self-hosted services
- **CrowdSec** with a Pi-hole bouncer (Suricata deferred - Helm chart schema issue)
- **ntfy** self-hosted on algol for fleet alerts, reached over the tailnet; the public ntfy.sh stays wired in as a fallback, so an algol outage can still report itself
- **GitHub Actions** on every PR: secret hygiene, `nix` evaluation of all ten hosts, `kustomize` + `kubeconform` over every overlay, shellcheck
- **stylix** for system-wide theming, **nixvim** for declarative Neovim

## Repo layout

```
flake.nix                       Inputs, tailnet IPs, theme; derives nixosConfigurations + colmena

.github/
├── workflows/ci.yml            Runs on every PR: secret hygiene, Nix eval, manifest validation, shellcheck
├── workflows/tailscale-acl.yml Tests the tailnet policy on PRs, applies it on merge to main
├── scripts/                    The checks, each runnable locally with no GitHub involved
└── encrypted-paths             Files that must always be SOPS-encrypted; CI enforces it

hosts/
├── default.nix                 THE HOST REGISTRY: hostName, roles, unfree, secrets, deploy
├── mkHost.nix                  Turns a registry entry into a module list (shared by both outputs)
├── roles.nix                   role -> {system, home, unfree} module lists
├── modules/
│   ├── system/                 NixOS modules
│   │   ├── profiles/           Selected per host by hosts/roles.nix
│   │   │   ├── base/           Implicit everywhere: nix, networking, tailscale, ssh, users
│   │   │   ├── server/         always-on.nix (role "server") + k3s-agent.nix (role "k3s-agent")
│   │   │   ├── desktop/        Shared by desktop hosts (bluetooth, sound, overlays)
│   │   │   ├── admin/          Heavy CLI tools (gh, kubectl, helm, flux, vault, colmena) - arcturus only
│   │   │   ├── gaming/         Steam + gamemode
│   │   │   └── wireless.nix    iwd, for the two portable hosts
│   │   └── host-specific/      Per-host: hardware-configuration.nix + overrides
│   ├── home/                   home-manager modules (mirrors the system/ layout)
│   │   ├── profiles/           base (shell, git, ssh), desktop (waybar, librewolf), editor (nixvim)
│   │   └── host-specific/      WM configs, host-specific waybar (GPU vs CPU thermals), oss (local-LLM CLI)
│   └── theme/                  Shared colours, fonts, wallpapers
└── non-nixos/                  Config in git for hardware Nix does not manage
    ├── phones/                 ADB debloat scripts - shell, not Nix
    │   ├── android.sh          Entrypoint; re-execs into nix-shell for android-tools
    │   ├── devices/            Per-device package lists (Algol, A16)
    │   ├── modules/            Reusable debloat actions (apps, config, debloat)
    │   └── lib/                adb.sh, keep.sh
    └── windows/                Win 11 slimming + hardening - PowerShell, not Nix
        ├── ntlite-components.md What to strip from the ISO, and what must stay
        ├── ntlite-preset.xml   Exported NTLite preset (add after building the ISO)
        ├── autounattend.xml    Install-time answers (bypasses, local accounts, no MSA)
        ├── harden.ps1          Telemetry, ads, Copilot/Recall; Defender + Update kept
        ├── lightweight.ps1     Shell and service trimming for an unaccelerated GPU
        ├── accounts.ps1        Standard user + "settings" admin, UAC at maximum
        └── README.md           Install order and the offline-until-passwords-set rule

secrets/
├── secrets.yaml                SOPS-encrypted, readable by the hosts in .sops.yaml
├── tailscale-policy.yaml       SOPS-encrypted tailnet grants policy; applied from CI, not by hand
└── vault-init.json             SOPS-encrypted Vault unseal keys + root token

k8s/
├── flux/
│   └── flux-system/            Flux bootstrap + cluster-config ConfigMap
├── apps/                       Workload Kustomizations (one folder per app)
│   ├── arr/                    Sonarr/Radarr/Lidarr/Bazarr/Prowlarr/qBittorrent behind gluetun,
│   │                           plus the decluttarr, recyclarr and arr-config reconcilers
│   ├── crowdsec/               IDS (Pi-hole bouncer now lives on argus as a systemd service)
│   ├── external-secrets/       Vault-backed runtime secrets
│   ├── fourget/                Self-hosted metasearch; upstream image, theme mounted as a ConfigMap
│   ├── immich/                 Photos
│   ├── ingress-nginx/
│   ├── jellyfin/               Media (video)
│   ├── kiwix/                  Offline Wikipedia mirror (kiwix-serve) on aperture
│   ├── monitoring/             Grafana stack
│   ├── navidrome/              Media (music)
│   ├── nextcloud/              Files + sync; pinned to albireo, data on its ext4 /bigstorage
│   ├── open-webui/             Chat UI in front of altair's llama-swap, via a Tailscale egress proxy
│   ├── oss-agent/              View-only ServiceAccount for the local-LLM CLI agent
│   ├── tailscale/
│   ├── vault/
│   ├── marketing-tool/         Version of an app I built during my internship at Enjoy Social
│   ├── prose/                  Own app; Postgres backend, Tailscale sidecar, Flux image automation
│   └── sewing-assistant/       Full-stack personal project to track my sewing projects
└── apps-config/                Post-deploy configs
    ├── authentik/              Authentik deployment + SSO blueprints
    ├── crowdsec/
    ├── external-secrets/
    └── grafana/
```

## Hosts

| Host      | Hardware                                                          | Role                                                                       |
|-----------|-------------------------------------------------------------------|----------------------------------------------------------------------------|
| Arcturus  | ThinkPad E490, i5 8th gen, 32 GB DDR4, Intel iGPU                 | Daily driver. Hyprland desktop. k3s control client (kubeconfig from SOPS). |
| Asta      | Lenovo ThinkServer TS140, Xeon E3-1246 v3 (4C/8T), 21 GB, RX 560 4 GB, 1.8 TB HDD | k3s server, media (Jellyfin, Navidrome), Vault, Flux source-of-truth. Headless. |
| Aperture  | Dell OptiPlex 3020, i5 4th gen, 12 GB DDR3, SSD + HDD, dGPU       | k3s agent. Headless.                                                       |
| Albireo   | Supermicro X9SCI/X9SCA, Xeon E3-1220 v2, 16 GB DDR3, 458 GB root + 2.7 TB /bigstorage | k3s agent. Nextcloud data, restic backup source, media sync, CrowdSec bouncer. Headless. |
| Avior     | Dell PowerEdge 1950, legacy DRAC + PXE boot          | NFS media server + k3s agent. Not yet installed; k3s is guarded off until its tailnet IP replaces `PLACEHOLDER`. |
| Amateus   | ThinkPad SL500 (refurb), Core 2 Duo, DDR2                         | Append-only restic repository + retention. Renders the fleet monitor on tty1. |
| Algol     | Dell Inspiron 5748, i7-4510U, 8 GB DDR3, 915 GB                   | Fleet monitoring collector (Loki + Grafana alerting) and self-hosted ntfy. Off-cluster. Headless. |
| Altair    | LGA1155 (P8H67-M PRO), i5-2500K, 24 GB DDR3, 128 GB SSD + 750 GB HDD, RX 580 + RX 570 (8 GB each) | Local LLM inference: llama-swap over llama.cpp/Vulkan, five models swapped on demand across 16 GB VRAM. Wake-on-LAN. Headless. |
| Argus     | Acer Aspire 7741, i3-380m (2C/4T, ~2010), 8 GB DDR3, BIOS       | Pi-hole + unbound. Tailnet DNS sentinel. Headless.                         |
| Alula     | Intel Compute Stick T6, Atom x5-Z8350, 4 GB RAM, 64 GB storage   | Portable niri desktop. Coding + browsing. Future cyberdeck base.           |

All hosts join via Tailscale. Ingress is tailnet-only. No public DNS, no port-forwarding for now.

## Deploy

```sh
sudo nixos-rebuild switch --flake .#<HostName>   # on the host itself; Arcturus is deploy = false
colmena apply --impure --on <HostName>           # remote; --impure is needed on a dirty tree
```

colmena node names are capitalised (`Altair`, not `altair`) - a lowercase name matches nothing and still exits 0.

## Things worth a read

- `hosts/modules/system/host-specific/altair/llama.nix` - `services.llama-swap` fronts several `llama-server` children on one port, which is what makes `--tensor-split` survivable: the split is per-model and swings +-70% on this hardware, so one global value is wrong for most models. Three details are load-bearing. `apiKeys = [ "${env.LLAMA_API_KEY}" ]` keeps the key out of the Nix store, but llama-swap is *default-allow* when that macro fails to expand, so a typo silently unauthenticates the whole endpoint rather than erroring. The llama-server macro must be `${PORT}` after Nix escaping, not an empty string. And because the model store is mounted `nofail`, `RequiresMountsFor` has to go in `unitConfig`: it's a `[Unit]` directive, systemd ignores it under `[Service]`, and the unit sets `PrivateMounts = true`, so without it the service gets a namespace that never sees the disk. Serving is tailnet-only on the strength of `trustedInterfaces` alone, with `openFirewall = false`; the children bind `127.0.0.1`.
- `hosts/modules/system/host-specific/arcturus/k3s-kubeconfig.nix` - `~/.kube/config` is a `mkOutOfStoreSymlink` to a SOPS-decrypted kubeconfig, so admin cluster credentials are declarative without ending up in the Nix store.
- `k8s/flux/flux-system/cluster-config.yaml` - the single ConfigMap every workload substitutes against.
- `hosts/modules/system/host-specific/asta/vault.nix` - Vault unseal driven by SOPS, ordered against `sops-nix.service` so it survives reboots.
- `hosts/non-nixos/phones/` - bonus: ADB-driven debloat for a Samsung Galaxy A16 5G (40+ packages removed, Knox left alone).

## Beyond the code

- [about/host-stories.md](about/host-stories.md) - where each machine came from, what was broken on it, and what it took to get it running
- [about/retrospective.md](about/retrospective.md) - what I'd do differently, and why
- [about/roadmap.md](about/roadmap.md) - what's next, and roughly when

---
Feedback and corrections welcome!
