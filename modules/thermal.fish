#!/usr/bin/env fish
# Module: Kernel Thermal Profiles
# Enables native acer_wmi thermal profile support on kernel 6.8+
# WARNING: Conflicts with core-damx (Linuwu-Sense blacklists acer_wmi)

set -g MODULE_NAME "Kernel Thermal Profiles"
set -g MODULE_ID "thermal"
set -g MODULE_DESCRIPTION "Native kernel thermal profiles via acer_wmi (requires kernel 6.8+)"

set -g _THERMAL_CONF "/etc/modprobe.d/acer-thermal-profiles.conf"

function module_detect
    if test "$SUPPORTS_THERMAL_PROFILES" = 1
        switch "$MODEL_FAMILY"
            case nitro predator helios triton
                return 0
        end
    end
    return 1
end

function module_check_installed
    test -f "$_THERMAL_CONF"
end

function module_install
    if test "$SUPPORTS_THERMAL_PROFILES" != 1
        error "Kernel 6.8+ required for native thermal profile support. Current: $KERNEL_VERSION"
    end

    # Conflict check
    if test -f /etc/modprobe.d/blacklist-acer-wmi.conf
        warn "acer_wmi is currently blacklisted (likely by Linuwu-Sense / DAMX)."
        warn "Native thermal profiles require acer_wmi to be loaded."
        warn "Using this module alongside DAMX may cause conflicts."
        if not confirm "Continue anyway?"
            log "Skipping thermal profile setup."
            return 0
        end
        log "Removing acer_wmi blacklist..."
        run_sudo rm -f /etc/modprobe.d/blacklist-acer-wmi.conf
    end

    log "Enabling Predator Sense v4 thermal profile support..."
    run_sudo tee "$_THERMAL_CONF" > /dev/null <<'EOF'
# Acer thermal profile support - Linuwu-DAMX Installer
# Enable Predator Sense v4 thermal profiles
options acer_wmi predator_v4=1
# Enable thermal profile cycling with mode button
options acer_wmi cycle_gaming_thermal_profile=1
EOF

    # GRUB parameter injection
    if test -f /etc/default/grub
        if not grep -q "acer_wmi.predator_v4" /etc/default/grub
            log "Adding thermal profile kernel parameter to GRUB..."
            run_sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="acer_wmi.predator_v4=1 /' /etc/default/grub
            run_sudo grub-mkconfig -o /boot/grub/grub.cfg
        end
    else if test -d /boot/loader/entries
        log "systemd-boot detected. Please manually add this kernel parameter:"
        log "  acer_wmi.predator_v4=1"
        log "  Edit files in /boot/loader/entries/ and add to the 'options' line."
    end

    set -ga INSTALLED_FILES $_THERMAL_CONF
    mark_reboot_required

    log "Thermal profiles configured. After reboot, use:"
    log "  cat /sys/firmware/acpi/platform_profile_choices  (list profiles)"
    log "  echo balanced | sudo tee /sys/firmware/acpi/platform_profile  (set profile)"
    log "  The mode button on your keyboard should now cycle through profiles."
end

function module_uninstall
    log "Removing thermal profile configuration..."
    sudo rm -f "$_THERMAL_CONF"

    if test -f /etc/default/grub
        if grep -q "acer_wmi.predator_v4" /etc/default/grub
            log "Removing thermal profile kernel parameter from GRUB..."
            sudo sed -i 's/acer_wmi\.predator_v4=1 //g' /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        end
    end
end

function module_verify
    if test -f /sys/firmware/acpi/platform_profile
        set -l profile (cat /sys/firmware/acpi/platform_profile 2>/dev/null)
        log "Active thermal profile: $profile"
        return 0
    end

    if test -f "$_THERMAL_CONF"
        warn "Config written but platform_profile not yet available (reboot required)"
        return 0
    end
    return 1
end
