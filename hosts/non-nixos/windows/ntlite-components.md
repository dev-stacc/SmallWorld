# NTLite component list

Applied to an official Windows 11 Pro ISO before install. Removing a component at image
level means it never lands on disk, which is lighter than installing it and switching it
off afterwards.

Export your preset from NTLite to `ntlite-preset.xml` in this directory once you've built
it — NTLite presets are plain XML, so the slimming decisions stay reviewable in git.

## Remove

- Consumer app bundle (Solitaire, Bing News/Weather, Maps, Alarms, Camera, People, Todos)
- Widgets, Copilot, Recall
- Teams consumer, Clipchamp, Your Phone, Outlook for Windows
- OneDrive
- Xbox stack (Game Bar, Gaming Overlay, Identity Provider, Speech-to-Text)
- Mixed Reality
- Cortana remnants
- Telemetry components
- Microsoft Edge — he installs a browser of choice
- Tablet and pen stacks — this machine has neither
- Hyper-V — nothing here virtualises

## Keep — removing these makes the install a dead end

- **Component Store / WinSxS and the servicing stack** — without it, no future update applies
- **Windows Update**
- **Windows Defender**
- **.NET and the Visual C++ runtimes** — most third-party software needs them
- **Drivers framework**
- **Microsoft Store** — unless he's certain he won't want it. Removing it blocks a lot of
  ordinary app installs later and is awkward to reverse.

## The risk worth naming

An over-aggressive preset installs cleanly and then fails to take the next annual feature
update, which means rebuilding from scratch. That is why "let Windows Update install at
least one real update end to end" is a hard verification step before the machine is handed
over, not an optional check.
