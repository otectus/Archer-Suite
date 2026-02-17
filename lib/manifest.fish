#!/usr/bin/env fish
# Install manifest tracking (Fish)
# Tracks what modules were installed for clean uninstallation

set -g MANIFEST_DIR "$HOME/.local/share/damx"
set -g MANIFEST_FILE "$MANIFEST_DIR/install-manifest.json"

# Write the install manifest after installation
# Usage: write_manifest "core-damx battery gpu" "file1 file2" "linuwu-sense/1.0" "envycontrol tlp"
function write_manifest
    set -l modules_str $argv[1]
    set -l files_str $argv[2]
    set -l dkms_str $argv[3]
    set -l packages_str $argv[4]

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
end

# Read installed modules from manifest
function read_manifest_modules
    if not test -f "$MANIFEST_FILE"
        echo ""
        return 1
    end
    python3 -c "
import json
with open('$MANIFEST_FILE') as f:
    data = json.load(f)
print(' '.join(data.get('modules_installed', [])))
"
end

# Read a specific field from manifest
function read_manifest_field
    set -l field $argv[1]
    if not test -f "$MANIFEST_FILE"
        echo ""
        return 1
    end
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
end

# Check if manifest exists
function has_manifest
    test -f "$MANIFEST_FILE"
end

# Remove the manifest file
function remove_manifest
    rm -f "$MANIFEST_FILE"
end
