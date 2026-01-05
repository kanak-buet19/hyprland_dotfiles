# Fix: Zen Browser Opening Dolphin Instead of Thunar

## Problem
Zen Browser (Firefox-based) ignores `xdg-mime` settings and uses DBus `org.freedesktop.FileManager1` interface. Dolphin registers this service, causing it to open even when Thunar is set as default.

## Solution

### 1. Set Thunar as System Default
Ensure `~/.config/mimeapps.list` contains:
```ini
[Default Applications]
inode/directory=thunar.desktop
application/x-gnome-saved-search=thunar.desktop
```

Verify with:
```bash
xdg-mime query default inode/directory
# Should return: thunar.desktop
```

### 2. Disable Dolphin's DBus Service
This is the **critical fix** that makes Zen use Thunar:

```bash
sudo mv /usr/share/dbus-1/services/org.kde.dolphin.FileManager1.service \
       /usr/share/dbus-1/services/org.kde.dolphin.FileManager1.service.bak
```

### 3. Kill Dolphin Process
```bash
killall dolphin
```

### 4. Restart Zen Browser
Close and reopen Zen Browser. Test by downloading a file and clicking "Open Containing Folder" - it should now open in Thunar.

## Permanent Fix
The DBus service rename is **permanent** and survives reboots. However, if you update the `dolphin` package, it may restore the service file. In that case, simply re-run step 2.

## Verification
Check available FileManager DBus services:
```bash
ls /usr/share/dbus-1/services/ | grep -i file
```

You should see:
- ✅ `org.xfce.Thunar.FileManager1.service` (active)
- ❌ `org.kde.dolphin.FileManager1.service.bak` (disabled)

## Note
**Do NOT run** `systemctl --user restart dbus` - it will freeze your system by killing all user services. The fix works without it.

---
**Applied on:** Arch Linux with Hyprland  
**Date:** January 2026
