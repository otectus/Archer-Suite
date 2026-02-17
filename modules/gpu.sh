#!/usr/bin/env bash
# Module: GPU Switching
# Installs EnvyControl for NVIDIA Optimus GPU mode management

MODULE_NAME="GPU Switching"
MODULE_ID="gpu"
MODULE_DESCRIPTION="EnvyControl for NVIDIA Optimus hybrid graphics switching"

module_detect() {
    # Relevant if NVIDIA dGPU + an integrated GPU
    if [ "$HAS_NVIDIA" -eq 1 ] && { [ "$HAS_INTEL_IGPU" -eq 1 ] || [ "$HAS_AMD_IGPU" -eq 1 ]; }; then
        return 0
    fi
    return 1
}

module_check_installed() {
    has_cmd envycontrol
}

module_install() {
    # Ensure NVIDIA driver is installed
    if ! pacman -Qi nvidia &>/dev/null && ! pacman -Qi nvidia-dkms &>/dev/null; then
        log "NVIDIA driver not installed. Installing nvidia-dkms..."
        run_sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils
        INSTALLED_PACKAGES+=" nvidia-dkms nvidia-utils"
    fi

    # Install EnvyControl
    if [ -n "$AUR_HELPER" ]; then
        log "Installing EnvyControl via $AUR_HELPER..."
        run $AUR_HELPER -S --needed --noconfirm envycontrol
    else
        log "No AUR helper found. Installing EnvyControl via pip..."
        run pip install envycontrol --break-system-packages 2>/dev/null || warn "pip install encountered issues."
    fi

    # GPU mode selection
    log "GPU Switching Modes:"
    log "  1) hybrid      - iGPU by default, NVIDIA on demand (recommended)"
    log "  2) nvidia       - Always use NVIDIA GPU (best performance)"
    log "  3) integrated   - Disable NVIDIA entirely (best battery life)"

    local gpu_mode="hybrid"
    if [ "$NO_CONFIRM" -eq 0 ]; then
        read -rp "Select mode [1]: " gpu_choice
        case "${gpu_choice:-1}" in
            2) gpu_mode="nvidia" ;;
            3) gpu_mode="integrated" ;;
            *) gpu_mode="hybrid" ;;
        esac
    fi

    log "Setting GPU mode to: $gpu_mode"
    if [ "$gpu_mode" = "hybrid" ]; then
        run_sudo envycontrol -s hybrid --rtd3 2
    else
        run_sudo envycontrol -s "$gpu_mode"
    fi

    INSTALLED_PACKAGES+=" envycontrol"
    mark_reboot_required
    log "GPU mode set to '$gpu_mode'. A reboot is required to apply changes."
}

module_uninstall() {
    log "Resetting GPU configuration..."
    if has_cmd envycontrol; then
        sudo envycontrol --reset 2>/dev/null || true
    fi
    log "EnvyControl package retained (remove manually if desired)."
}

module_verify() {
    if has_cmd envycontrol; then
        local mode
        mode=$(envycontrol --query 2>/dev/null || echo "unknown")
        log "Current GPU mode: $mode"
        return 0
    fi
    warn "EnvyControl not found"
    return 1
}
