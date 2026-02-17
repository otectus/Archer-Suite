#!/usr/bin/env bash
# Linuwu-DAMX Unified Uninstaller v2.0
# Supports manifest-based selective uninstall with legacy fallback

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/detect.sh"
source "$SCRIPT_DIR/lib/manifest.sh"

section "Linuwu-DAMX Uninstaller"

if has_manifest; then
    log "Install manifest found. Performing targeted uninstall."
    echo ""

    INSTALLED_MODS=$(read_manifest_modules)
    log "Installed modules: $INSTALLED_MODS"
    echo ""

    for mod in $INSTALLED_MODS; do
        local_mod_file="$SCRIPT_DIR/modules/${mod}.sh"
        if [ -f "$local_mod_file" ]; then
            log "Uninstalling: $mod"
            source "$local_mod_file"
            module_uninstall
            success "Removed: $mod"
        else
            warn "Module file not found: $local_mod_file (skipping)"
        fi
        echo ""
    done

    # Remove manifest
    remove_manifest
    log "Install manifest removed."

else
    warn "No install manifest found. Performing legacy uninstall."
    warn "This will attempt to remove all known components."
    echo ""

    # Legacy uninstall: same as original v1 behavior
    # 1. Disable Services
    log "Stopping and disabling DAMX Daemon..."
    systemctl --user disable --now damx-daemon.service 2>/dev/null || true
    rm -f "$HOME/.config/systemd/user/damx-daemon.service"
    systemctl --user daemon-reload

    # 2. Remove Driver (DKMS)
    log "Removing Linuwu-Sense DKMS module..."
    sudo dkms remove -m linuwu-sense -v 1.0 --all 2>/dev/null || true
    sudo rm -rf "/usr/src/linuwu-sense-1.0"

    # 3. Remove Blacklist
    log "Restoring acer_wmi (removing blacklist)..."
    sudo rm -f /etc/modprobe.d/blacklist-acer-wmi.conf

    # 4. Remove other possible configs from v2 modules
    sudo rm -f /etc/modprobe.d/touchpad-amd-fix.conf
    sudo rm -f /etc/modprobe.d/acer-audio-amd.conf
    sudo rm -f /etc/modprobe.d/acer-thermal-profiles.conf
    sudo rm -f /etc/udev/rules.d/99-acer-battery-health.rules
    sudo rm -f /etc/tlp.d/01-acer-optimize.conf

    # Remove touchpad service if present
    if [ -f /etc/systemd/system/touchpad-fix.service ]; then
        sudo systemctl disable touchpad-fix.service 2>/dev/null || true
        sudo rm -f /etc/systemd/system/touchpad-fix.service
        sudo systemctl daemon-reload
    fi

    # Remove acer-wmi-battery DKMS if present
    sudo dkms remove -m acer-wmi-battery -v 0.1.0 --all 2>/dev/null || true
    sudo rm -rf "/usr/src/acer-wmi-battery-0.1.0"

    # 5. Clean application files
    log "Removing DAMX files..."
    rm -rf "$HOME/.local/share/damx"
fi

section "Cleanup Complete"
success "All installed components have been removed."
echo ""
warn "You may need to reboot to fully restore default driver behavior."
