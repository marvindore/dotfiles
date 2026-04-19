#!/usr/bin/env bash

# uninstall-kanata-service.sh
# Safely reverses the installation of Karabiner DriverKit, Kanata, and LaunchDaemons

PLIST_DIR="/Library/LaunchDaemons"

echo "=== 1. Stopping and Unloading Services ==="
# Bootout (unload) the services. The '|| true' ensures the script continues even if already stopped.
sudo launchctl bootout system "${PLIST_DIR}/com.example.kanata.plist" 2>/dev/null || true
sudo launchctl bootout system "${PLIST_DIR}/com.example.karabiner-vhiddaemon.plist" 2>/dev/null || true
sudo launchctl bootout system "${PLIST_DIR}/com.example.karabiner-vhidmanager.plist" 2>/dev/null || true

echo "=== 2. Deactivating Karabiner System Extension ==="
# Gracefully deactivate the system extension before deleting the app
if [ -f "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager" ]; then
    sudo "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager" deactivate 2>/dev/null || true
fi

echo "=== 3. Removing LaunchDaemon Plists ==="
sudo rm -f "${PLIST_DIR}/com.example.kanata.plist"
sudo rm -f "${PLIST_DIR}/com.example.karabiner-vhiddaemon.plist"
sudo rm -f "${PLIST_DIR}/com.example.karabiner-vhidmanager.plist"

echo "=== 4. Removing Karabiner DriverKit Files ==="
sudo rm -rf "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice"
sudo rm -rf "/Applications/.Karabiner-VirtualHIDDevice-Manager.app"

echo "=== 5. Uninstalling Kanata ==="
if brew list kanata >/dev/null 2>&1; then
    brew uninstall kanata
else
    echo "Kanata is not installed via Homebrew or already removed."
fi

# Optional: Remove Kanata configuration
# Uncomment the line below if you also want to permanently delete your kanata config file
# rm -rf "${HOME}/.config/kanata"

echo ""
echo "============================================================"
echo "✅ Uninstallation Complete! A few manual cleanup steps remain:"
echo "============================================================"
echo "1. Privacy & Security > Accessibility: Open System Settings and remove (using the '-' button) 'kanata'."
echo "2. Privacy & Security > Input Monitoring: Open System Settings and remove 'kanata'."
echo ""
echo "To quickly jump to these settings, run:"
echo "open \"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility\""
echo "open \"x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent\""
echo ""
echo "⚠️ Note: Please restart your Mac to ensure macOS clears the deactivated System Extension from its cache."
