#!/usr/bin/env fish
# Shared utility functions for Linuwu-DAMX Installer (Fish)

set -g INSTALLER_VERSION "2.0.0"
set -q DRY_RUN; or set -g DRY_RUN 0
set -q NO_CONFIRM; or set -g NO_CONFIRM 0
set -g REBOOT_REQUIRED 0

function log
    echo (set_color cyan)">>> "(set_color normal)$argv
end

function warn
    echo (set_color yellow)"\u26a0  "(set_color normal)$argv
end

function error
    echo (set_color red)"\u274c "(set_color normal)$argv
    exit 1
end

function success
    echo (set_color green)"\u2705 "(set_color normal)$argv
end

# Execute a command, or print it in dry-run mode
function run
    if test "$DRY_RUN" = 1
        echo (set_color yellow)"[DRY RUN]"(set_color normal) $argv
        return 0
    end
    $argv
end

# Execute a command with sudo, or print it in dry-run mode
function run_sudo
    if test "$DRY_RUN" = 1
        echo (set_color yellow)"[DRY RUN]"(set_color normal) sudo $argv
        return 0
    end
    sudo $argv
end

# Prompt for confirmation (respects NO_CONFIRM)
function confirm
    set -l prompt $argv[1]
    test -z "$prompt"; and set prompt "Continue?"
    if test "$NO_CONFIRM" = 1
        return 0
    end
    read -P "$prompt [y/N]: " answer
    string match -rqi '^y' "$answer"
end

# Mark that a reboot is needed
function mark_reboot_required
    set -g REBOOT_REQUIRED 1
end

# Detect the script's own directory
function detect_script_dir
    set -l script_path (status filename)
    dirname (realpath "$script_path")/..
end

# Print a section header
function section
    echo ""
    echo (set_color --bold)"=== $argv ==="(set_color normal)
    echo ""
end

# Check if a command exists
function has_cmd
    command -v $argv[1] >/dev/null 2>&1
end
