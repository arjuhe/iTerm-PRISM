#!/usr/bin/env bash
#
# Cleanup duplicate PATH entries in shell profiles
# Removes redundant export PATH lines that reference ~/.local/bin
#

set -e

TARGET_DIR="${HOME}/.local/bin"
SHELL_PROFILES=(
    "${HOME}/.bash_profile"
    "${HOME}/.bashrc"
    "${HOME}/.zshrc"
    "${HOME}/.profile"
)

echo "Scanning for duplicate PATH entries referencing $TARGET_DIR..."
echo ""

for profile in "${SHELL_PROFILES[@]}"; do
    if [[ ! -f "$profile" ]]; then
        continue
    fi

    count=$(grep -c "export PATH=.*${TARGET_DIR}" "$profile" 2>/dev/null) || count=0

    if [[ $count -gt 1 ]]; then
        echo "Found $count entries in $profile"

        # Create backup
        cp "$profile" "${profile}.backup"
        echo "  (Backed up to ${profile}.backup)"

        # Remove all iTerm-PRISM-added entries
        grep -v "# Added by iTerm-PRISM installer" "$profile" > "${profile}.tmp" || true
        grep -v "export PATH=.*${TARGET_DIR}" "${profile}.tmp" > "${profile}.clean" || true

        # Add back a single entry
        if [[ -s "${profile}.clean" ]]; then
            cat "${profile}.clean" > "$profile"
        fi
        echo "" >> "$profile"
        echo "# Added by iTerm-PRISM installer" >> "$profile"
        echo "export PATH=\"\${HOME}/.local/bin:\$PATH\"" >> "$profile"

        # Cleanup temp files
        rm -f "${profile}.tmp" "${profile}.clean"

        echo "  ✓ Cleaned up - kept single entry"
        echo ""
    fi
done

echo "Done. Reload your shell to apply changes:"
echo "  source ~/.bash_profile"
