#!/usr/bin/env fish
# Module: GPU Switching
# Installs EnvyControl for NVIDIA Optimus GPU mode management

set -g MODULE_NAME "GPU Switching"
set -g MODULE_ID "gpu"
set -g MODULE_DESCRIPTION "EnvyControl for NVIDIA Optimus hybrid graphics switching"

function module_detect
    if test "$HAS_NVIDIA" = 1
        if test "$HAS_INTEL_IGPU" = 1; or test "$HAS_AMD_IGPU" = 1
            return 0
        end
    end
    return 1
end

function module_check_installed
    has_cmd envycontrol
end

function module_install
    # Ensure NVIDIA driver is installed
    if not pacman -Qi nvidia >/dev/null 2>&1; and not pacman -Qi nvidia-dkms >/dev/null 2>&1
        log "NVIDIA driver not installed. Installing nvidia-dkms..."
        run_sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils
        set -ga INSTALLED_PACKAGES nvidia-dkms nvidia-utils
    end

    # Install EnvyControl
    if test -n "$AUR_HELPER"
        log "Installing EnvyControl via $AUR_HELPER..."
        run $AUR_HELPER -S --needed --noconfirm envycontrol
    else
        log "No AUR helper found. Installing EnvyControl via pip..."
        run pip install envycontrol --break-system-packages 2>/dev/null; or warn "pip install encountered issues."
    end

    # GPU mode selection
    log "GPU Switching Modes:"
    log "  1) hybrid      - iGPU by default, NVIDIA on demand (recommended)"
    log "  2) nvidia       - Always use NVIDIA GPU (best performance)"
    log "  3) integrated   - Disable NVIDIA entirely (best battery life)"

    set -l gpu_mode "hybrid"
    if test "$NO_CONFIRM" = 0
        read -P "Select mode [1]: " gpu_choice
        switch "$gpu_choice"
            case 2
                set gpu_mode "nvidia"
            case 3
                set gpu_mode "integrated"
            case '*'
                set gpu_mode "hybrid"
        end
    end

    log "Setting GPU mode to: $gpu_mode"
    if test "$gpu_mode" = "hybrid"
        run_sudo envycontrol -s hybrid --rtd3 2
    else
        run_sudo envycontrol -s $gpu_mode
    end

    set -ga INSTALLED_PACKAGES envycontrol
    mark_reboot_required
    log "GPU mode set to '$gpu_mode'. A reboot is required to apply changes."
end

function module_uninstall
    log "Resetting GPU configuration..."
    if has_cmd envycontrol
        sudo envycontrol --reset 2>/dev/null; or true
    end
    log "EnvyControl package retained (remove manually if desired)."
end

function module_verify
    if has_cmd envycontrol
        set -l mode (envycontrol --query 2>/dev/null; or echo "unknown")
        log "Current GPU mode: $mode"
        return 0
    end
    warn "EnvyControl not found"
    return 1
end
