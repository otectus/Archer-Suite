#!/usr/bin/env bash
# Install manifest tracking (Bash)
# Tracks what modules were installed for clean uninstallation

MANIFEST_DIR="$HOME/.local/share/damx"
MANIFEST_FILE="$MANIFEST_DIR/install-manifest.json"

# Write the install manifest after installation
# Usage: write_manifest "core-damx battery gpu" "file1 file2" "linuwu-sense/1.0" "envycontrol tlp"
write_manifest() {
    local modules_str="$1"
    local files_str="$2"
    local dkms_str="$3"
    local packages_str="$4"

    mkdir -p "$MANIFEST_DIR"

    python3 -c "
import json, datetime
manifest = {
    'install_date': datetime.datetime.now().isoformat(),
    'installer_version': '$INSTALLER_VERSION',
    'acer_model': '$ACER_PRODUCT_NAME',
    'model_family': '$MODEL_FAMILY',
    'kernel_version': '$KERNEL_VERSION',
    'modules_installed': '$modules_str'.split(),
    'files_created': '$files_str'.split(),
    'dkms_modules': '$dkms_str'.split(),
    'packages_installed': '$packages_str'.split()
}
with open('$MANIFEST_FILE', 'w') as f:
    json.dump(manifest, f, indent=2)
"
    log "Install manifest written to $MANIFEST_FILE"
}

# Read installed modules from manifest
# Returns space-separated list of module IDs
read_manifest_modules() {
    if [ ! -f "$MANIFEST_FILE" ]; then
        echo ""
        return 1
    fi
    python3 -c "
import json
with open('$MANIFEST_FILE') as f:
    data = json.load(f)
print(' '.join(data.get('modules_installed', [])))
"
}

# Read a specific field from manifest
read_manifest_field() {
    local field="$1"
    if [ ! -f "$MANIFEST_FILE" ]; then
        echo ""
        return 1
    fi
    python3 -c "
import json
with open('$MANIFEST_FILE') as f:
    data = json.load(f)
val = data.get('$field', [])
if isinstance(val, list):
    print(' '.join(val))
else:
    print(val)
"
}

# Check if manifest exists
has_manifest() {
    [ -f "$MANIFEST_FILE" ]
}

# Remove the manifest file
remove_manifest() {
    rm -f "$MANIFEST_FILE"
}
