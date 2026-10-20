# Host stories

Every machine here has a history.

**Arcturus** A ThinkPad E490 (i5 8th gen, Intel iGPU). Bought 2018-19 for the CÉGEP with Windows 10 that auto-promoted itself to 11. The 4 GB Windows baseline made IDEs crawl, so I switched to Linux Mint, then Arch (dependency-conflict hell, dotfile sprawl), then NixOS. Since then: 32 GB RAM, new battery, and a two-heatpipe heatsink swap I had to do twice because the first Amazon seller shipped an E480 part claiming it fit and I found one on Alibaba that actually fit. Stock E490s idles at 50-65 °C, this one usually stays around 40, and the workflow usually fits in 3 GB so the 32 is overkill in the best way.

**Asta** A stripped-down Toshiba Satellite L-855 (socketed AMD A8/A10, ~10+ years old) my brother handed down. I tore off the shell and standoffed the motherboard onto a serving tray with the HDD, RAM, and heatsink. At that point it was literally going to serve things. 16 GB DDR3 upgrade done, CPU swap planned. First node in the cluster.

**Amateus** A refurbished ThinkPad SL500 from eBay, missing a few keys but the seller was honest about it. Cleaned, repasted, +2 GB DDR2. Keyboard feels great even with the gaps. Used to be the k3s agent. Eventual plan is a modern-internals mod in the spirit of the X210AI project (modern CPU, DDR5, NVMe inside the vintage chassis).

**Aperture** A refurbished Dell OptiPlex 3020 from eBay, $80. i5 4th gen, 12 GB DDR3, SSD + HDD, dedicated GPU. Light dust, fresh paste, NixOS, `git pull`, done. That was the fastest a host has ever joined this cluster. Original case kept. It's now the k3s agent, taking over the role Amateus used to fill.

**Altair** The successor to Antinoos, and the reason Antinoos is gone. Antinoos began as a light-gaming desktop on a retired Acer Aspire board of my mom's (i5 6th gen, 16 GB DDR3, 3 TB storage), because the console subscription model was going to cost more than this over time. Its first RX 580 was a defective eBay refurb that mostly worked, then didn't (probably ex-mining); replaced with a sealed, tested card and a new Corsair PSU. It drove 4K@60 over Polaris under Sway, after Hyprland kept dying with `eglDupNativeFenceFDANDROID EGL_BAD_PARAMETER` that `AQ_NO_ATOMIC=1` + `AQ_NO_MODIFIERS=1` couldn't fully fix — `WLR_DRM_NO_ATOMIC=1` + `WLR_NO_HARDWARE_CURSORS=1` on Sway is what finally kept the panel up. Now its root HDD and its RX 580 have moved onto an LGA1155 board (i5-2500K) with two PCIe x16 slots, joined by a 1 TB model store. The second slot first took the card pulled out of Albireo, which turned out to be broken and unhappy in a dual-GPU setup, so an RX 570 won on an eBay gamble took its place. Two 8 GB Polaris cards is 16 GB of VRAM. It now serves gpt-oss-20b (Q4_K_M, a mixture-of-experts model) at ~43 tok/s; a dense 14B at Q5 managed 14 tok/s on the same hardware, which is why the MoE won. ROCm dropped gfx803 years ago, so the stack is llama.cpp on Vulkan rather than anything ROCm-based. Normally powered off, woken by a magic packet. Local inference is worth understanding while it's still unrestricted.

**Argus** An Acer Aspire 7741 from ~2010 vintage. The screen and keyboard were broken. Cleaned, repasted, and wiped the HDD. Getting into the BIOS to change the boot order was its own little battle because of windows. Will eventuall strip it down to the motherboard in the spirit of Asta. It's currently running Pi-Hole 24/7.

**Alula** An Intel Compute Stick T6 from eBay. Wanted something portable with real x86 compatibility rather than a Pi, plus the nostalgia factor of a full PC on a stick. 4 GB RAM and 64 GB storage covers nixvim, Brave, and a terminal. Niri made sense over a traditional tiling WM since scrollable columns adapt better to whatever screen is nearby. Long-term plan is a modular cyberdeck build around it.

## Honourable mention

**Sanctuary** A Raspberry Pi Zero 2 W running Pi-hole + unbound on Raspberry Pi OS. Not part of this flake (16 GB of storage rules NixOS out for now), but it's where this whole homelab started. The orbital-sync systemd timers in `hosts/modules/system/host-specific/argus/pihole-sync.nix` keep this Pi and Argus's Pi-hole mirroring each other.
