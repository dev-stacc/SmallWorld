# Windows 11, lightweight and safe

Configuration for the spare A8 laptop (AMD A8-4500M/5550M, 8-16 GB DDR3). Not a NixOS
host — this directory holds the install answers and post-install scripts so the setup is
reproducible, the same way `../phones/` does for Android.

Windows 11 Pro, unactivated: free, never expires, and still receives security updates. Every
free Windows 10 route has been EOL since October 2025, so this is the only free option that
stays patched. The cost is a desktop watermark and personalisation settings locked in the UI.

**Known limitation.** Trinity/Richland graphics are VLIW4 — DirectX 11, WDDM 1.3. Windows 11
requires a DX12 / WDDM 2.0 driver and AMD's last driver for these parts was Crimson 16.2.1
(2016, Windows 10 only). Windows runs on the Microsoft Basic Display Adapter: correct native
resolution, but no hardware acceleration and no video decode. That is why `lightweight.ps1`
matters here rather than being cosmetic — with no GPU to lean on, shell overhead is felt
directly.

## Install order

1. **Check the disk first.** If it's still the original 5400rpm drive, a ~$35 SATA SSD will
   matter more than everything in this directory combined.
2. Slim an official Windows 11 Pro ISO in NTLite using `ntlite-components.md`. Export the
   preset here as `ntlite-preset.xml`.
3. Write the ISO to USB and copy `autounattend.xml` to the root of the stick.
4. BIOS: AHCI on, UEFI if the firmware offers it.
5. Install. The answer file accepts the EULA, applies the TPM/SecureBoot/CPU bypasses this
   machine needs, skips the Microsoft account, and creates both local accounts.
6. **Stay offline** and log in as `settings`, then run the scripts in order:

   ```powershell
   .\accounts.ps1 -User <his-account-name>
   .\harden.ps1
   .\lightweight.ps1
   ```

7. Reboot, connect to the network, and let Windows Update install at least one real update
   end to end. This is the check that catches an over-aggressive NTLite preset.

## Why offline until accounts.ps1 has run

`autounattend.xml` creates both accounts with **no password**, because this repository is
public and an answer file with credentials in it — even base64-"obfuscated" ones — would be
a credential leak. `accounts.ps1` prompts for both passwords on first boot. Until it has
run, the machine has a passwordless administrator, so it must not be on a network.

## Accounts

| account | group | purpose |
| --- | --- | --- |
| his name | Users (Standard) | day-to-day |
| `settings` | Administrators | elevation, installs, maintenance |

Named `settings` so it reads as a system function rather than someone else's account on his
laptop. He runs as a standard user, so installing software prompts for the `settings`
password instead of a yes/no click. If he holds that password the friction is small and the
benefit is smaller — but not zero: malware still cannot elevate silently, it has to raise a
credential prompt he didn't initiate.

## Placeholders to fill in

`autounattend.xml` contains `CHANGEME` in three places for two values: the computer name,
and his account name (as both `Name` and `DisplayName`). All must be set before use.

## What CI does not check

`.github/scripts/check-shell.sh` globs `git ls-files '*.sh'`, so nothing here is linted.
Run `Invoke-ScriptAnalyzer` against the `.ps1` files in the guest if you want them checked.
