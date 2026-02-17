#!/usr/bin/env bash
# Shared utility functions for Linuwu-DAMX Installer (Bash)

# Colors
_CYAN="\033[0;36m"
_RED="\033[0;31m"
_YELLOW="\033[0;33m"
_GREEN="\033[0;32m"
_BOLD="\033[1m"
_RESET="\033[0m"

INSTALLER_VERSION="2.0.0"
DRY_RUN="${DRY_RUN:-0}"
NO_CONFIRM="${NO_CONFIRM:-0}"
REBOOT_REQUIRED=0

log()   { echo -e "${_CYAN}>>>${_RESET} $*"; }
warn()  { echo -e "${_YELLOW}\u26a0${_RESET}  $*"; }
error() { echo -e "${_RED}\u274c${_RESET} $*"; exit 1; }
success() { echo -e "${_GREEN}\u2705${_RESET} $*"; }

# Execute a command, or print it in dry-run mode
run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "${_YELLOW}[DRY RUN]${_RESET} $*"
        return 0
    fi
    "$@"
}

# Execute a command with sudo, or print it in dry-run mode
run_sudo() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "${_YELLOW}[DRY RUN]${_RESET} sudo $*"
        return 0
    fi
    sudo "$@"
}

# Prompt for confirmation (respects --no-confirm)
confirm() {
    local prompt="${1:-Continue?}"
    if [ "$NO_CONFIRM" -eq 1 ]; then
        return 0
    fi
    read -rp "$prompt [y/N]: " answer
    [[ "${answer,,}" == "y" ]]
}

# Mark that a reboot is needed
mark_reboot_required() {
    REBOOT_REQUIRED=1
}

# Detect the script's own directory
detect_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

# Print a section header
section() {
    echo ""
    echo -e "${_BOLD}=== $* ===${_RESET}"
    echo ""
}

# Check if a command exists
has_cmd() {
    command -v "$1" &>/dev/null
}
