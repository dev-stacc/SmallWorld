# container

A Shelter-owned managed profile (user id 10) that sandboxes GMS-dependent apps
(Discord, Instagram, TikTok) so the main profile stays Google-free. KISS
launcher doesn't show work-profile apps, so home-screen icons go through
Termux:Widget + Shizuku `rish` trampolines that `am start --user 10` into the
container.

## one-time setup (manual)

If Shelter's in-app wizard fails (Knox blocks DPM provisioning on Samsung), do
it from adb:

```
adb shell pm create-user --profileOf 0 --managed Container
# note the new user id (typically 10)
adb shell pm install-existing --user 10 net.typeblog.shelter
adb shell dpm set-profile-owner --user 10 net.typeblog.shelter/.receivers.ShelterDeviceAdminReceiver
adb shell am start-user 10
```

Then sideload the apps:

```
# GMS + GSF: enable the existing system copy for user 10
adb shell pm install-existing --user 10 com.google.android.gms
adb shell pm install-existing --user 10 com.google.android.gsf

# Discord / Instagram / TikTok: install the staged XAPKs
install_xapk_user $OUTDIR/com.discord.xapk            discord   10
install_xapk_user $OUTDIR/com.instagram.android.xapk  instagram 10
install_xapk_user $OUTDIR/com.zhiliaoapp.musically.xapk tiktok  10

# remove from main profile
for pkg in com.discord com.instagram.android com.zhiliaoapp.musically; do
  adb shell pm uninstall --user 0 "$pkg"
done
```

## KISS shortcuts via Termux:Widget + rish

Install Termux:Widget (`com.termux.widget` on F-Droid) on the main profile,
then in Termux:

```
pkg install rish termux-tools
rish          # tap Authorize in the Shizuku prompt
mkdir -p ~/.shortcuts
cp /path/to/this/repo/modules/apps/container/{discord,instagram,tiktok} ~/.shortcuts/
chmod +x ~/.shortcuts/*
```

Long-press the home screen → Widgets → Termux:Widget → place one shortcut
widget per script.

If new container apps are added, copy this pattern and look up the launcher
component with:

```
adb shell cmd package resolve-activity --user 10 -c android.intent.category.LAUNCHER <pkg>
```
