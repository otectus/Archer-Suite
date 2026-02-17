#!/usr/bin/env fish
# Linuwu-DAMX Unified Uninstaller v2.0 (Fish)
# Supports manifest-based selective uninstall with legacy fallback

set -g SCRIPT_DIR (realpath (dirname (status filename)))

# Source utilities
source "$SCRIPT_DIR/lib/utils.fish"
source "$SCRIPT_DIR/lib/detect.fish"
source "$SCRIPT_DIR/lib/manifest.fish"

section "Linuwu-DAMX Uninstaller"

if has_manifest
    log "Install manifest found. Performing targeted uninstall."
    echo ""

    set -l installed_mods (read_manifest_modules)
    log "Installed modules: $installed_mods"
    echo ""

    for mod in (string split " " "$installed_mods")
        set -l local_mod_file "$SCRIPT_DIR/modules/$mod.fish"
        if test -f "$local_mod_file"
            log "Uninstalling: $mod"
            source "$local_mod_file"
            module_uninstall
            success "Removed: $mod"
        else
            warn "Module file not found: $local_mod_file (skipping)"
        end
        echo ""
    end

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
    systemctl --user disable --now damx-daemon.service 2>/dev/null; or true
    rm -f $HOME/.config/systemd/user/damx-daemon.service
    systemctl --user daemon-reload

    # 2. Remove Driver (DKMS)
    log "Removing Linuwu-Sense DKMS module..."
    sudo dkms remove -m linuwu-sense -v 1.0 --all 2>/dev/null; or true
    sudo rm -rf /usr/src/linuwu-sense-1.0

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
    if test -f /etc/systemd/system/touchpad-fix.service
        sudo systemctl disable touchpad-fix.service 2>/dev/null; or true
        sudo rm -f /etc/systemd/system/touchpad-fix.service
        sudo systemctl daemon-reload
    end

    # Remove acer-wmi-battery DKMS if present
    sudo dkms remove -m acer-wmi-battery -v 0.1.0 --all 2>/dev/null; or true
    sudo rm -rf /usr/src/acer-wmi-battery-0.1.0

    # 5. Clean application files
    log "Removing DAMX files..."
    rm -rf $HOME/.local/share/damx
end

section "Cleanup Complete"
success "All installed components have been removed."
echo ""
warn "You may need to reboot to fully restore default driver behavior."
