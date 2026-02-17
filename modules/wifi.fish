#!/usr/bin/env fish
# Module: WiFi/Bluetooth Troubleshooting
# Diagnoses and fixes wireless connectivity issues

set -g MODULE_NAME "WiFi/Bluetooth Troubleshooting"
set -g MODULE_ID "wifi"
set -g MODULE_DESCRIPTION "Diagnose and fix WiFi/Bluetooth issues for various chipsets"

function module_detect
    test "$WIFI_CHIPSET" = "mediatek"
end

function module_check_installed
    return 1
end

function module_install
    log "Installing/updating wireless firmware packages..."
    run_sudo pacman -S --needed --noconfirm linux-firmware

    switch "$WIFI_CHIPSET"
        case mediatek
            log "MediaTek chipset detected: $WIFI_DEVICE"
            _fix_mediatek
        case intel
            log "Intel chipset detected: $WIFI_DEVICE"
            _fix_intel
        case realtek
            log "Realtek chipset detected: $WIFI_DEVICE"
            _fix_realtek
        case qualcomm
            log "Qualcomm/Atheros chipset detected: $WIFI_DEVICE"
            log "Qualcomm chipsets generally have good Linux support."
            log "If you experience issues, ensure linux-firmware is up to date."
        case '*'
            log "WiFi chipset: $WIFI_DEVICE"
            log "No chipset-specific fixes available. Ensuring firmware is current."
    end

    _setup_bluetooth

    if has_cmd nmcli
        if not systemctl is-active --quiet NetworkManager.service 2>/dev/null
            log "Enabling NetworkManager..."
            run_sudo systemctl enable --now NetworkManager.service
        end
    end

    log "WiFi/Bluetooth configuration complete."
    set -ga INSTALLED_PACKAGES linux-firmware
end

function _fix_mediatek
    if dmesg 2>/dev/null | grep -qi "mt79.*firmware.*failed|mt79.*firmware.*error"
        warn "MediaTek firmware loading failure detected."
        log "Attempting PCIe device reset..."

        set -l pci_addr (lspci -D 2>/dev/null | grep -i "mediatek.*network|mediatek.*wireless" | awk '{print $1}')
        if test -n "$pci_addr"
            echo 1 | run_sudo tee "/sys/bus/pci/devices/$pci_addr/remove" > /dev/null 2>&1; or true
            sleep 2
            echo 1 | run_sudo tee /sys/bus/pci/rescan > /dev/null 2>&1; or true
            log "PCIe device reset completed."
        else
            warn "Could not find MediaTek PCI address for reset."
        end
    end

    if string match -rqi 'MT7921|MT7922' "$WIFI_DEVICE"
        log "MT7921/MT7922 detected. These chipsets require kernel 5.12+ for basic support."
        log "Kernel 6.2+ recommended for stability."
        if test "$KERNEL_MAJOR" -lt 6
            warn "Your kernel ($KERNEL_VERSION) may not fully support this chipset."
        end
    end

    if string match -rqi 'MT7925' "$WIFI_DEVICE"
        warn "MT7925e detected. This chipset has limited Linux support."
        warn "Known issues: low signal reception, intermittent disconnects."
        warn "Consider replacing with an Intel AX210 for better Linux compatibility."
    end
end

function _fix_intel
    if rfkill list bluetooth 2>/dev/null | grep -qi "Soft blocked: yes"
        log "Bluetooth is soft-blocked. Unblocking..."
        run_sudo rfkill unblock bluetooth
    end
    if rfkill list wifi 2>/dev/null | grep -qi "Soft blocked: yes"
        log "WiFi is soft-blocked. Unblocking..."
        run_sudo rfkill unblock wifi
    end

    if string match -rqi 'AX210|AX211|BE200' "$WIFI_DEVICE"
        log "Intel AX210/AX211/BE200 detected. Checking firmware..."
        if dmesg 2>/dev/null | grep -qi "iwlwifi.*firmware.*error|iwlwifi.*no suitable firmware"
            warn "Intel WiFi firmware issue detected."
            log "Try: sudo pacman -S linux-firmware (already done above)"
            mark_reboot_required
        end
    end
end

function _fix_realtek
    log "Some Realtek adapters require out-of-tree drivers."
    log "Common AUR packages for Realtek WiFi:"
    log "  - rtw89-dkms-git (for RTL8852/RTL8922 series)"
    log "  - rtl8821cu-morrownr-dkms-git (for RTL8821CU USB)"

    if test -n "$AUR_HELPER"
        log "You can install these with: $AUR_HELPER -S <package-name>"
    else
        log "Install an AUR helper (yay or paru) to install these packages."
    end
end

function _setup_bluetooth
    if not pacman -Qi bluez >/dev/null 2>&1
        log "Installing Bluetooth packages..."
        run_sudo pacman -S --needed --noconfirm bluez bluez-utils
    end

    if not systemctl is-active --quiet bluetooth.service 2>/dev/null
        log "Enabling Bluetooth service..."
        run_sudo systemctl enable --now bluetooth.service
    end
end

function module_uninstall
    log "WiFi module: No persistent changes to remove."
    log "Firmware packages retained as they are standard system components."
end

function module_verify
    if ip link 2>/dev/null | grep -q "wl"
        return 0
    end
    warn "No wireless interface detected"
    return 1
end
