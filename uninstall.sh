#!/usr/bin/env bash
#
# iTerm-PRISM Uninstaller
# Clean removal of iTerm-PRISM and optional cleanup
#

set -e
set -u
set -o pipefail

# Configuration
INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_NAME="prism"

# Shell profile detection (priority order)
SHELL_PROFILES=(
    "${HOME}/.bash_profile"
    "${HOME}/.bashrc"
    "${HOME}/.zshrc"
    "${HOME}/.profile"
)

# =============================================================================
# Color Setup
# =============================================================================

setup_colors() {
    if tput setaf 1 >/dev/null 2>&1; then
        BOLD=$(tput bold)
        RESET=$(tput sgr0)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        CYAN=$(tput setaf 6)
        RED=$(tput setaf 1)
    else
        BOLD=""
        RESET=""
        GREEN=""
        YELLOW=""
        BLUE=""
        CYAN=""
        RED=""
    fi
}

# =============================================================================
# Display Functions
# =============================================================================

print_banner() {
    echo ""
    echo "${BOLD}${RED}iTerm-PRISM Uninstaller${RESET}"
    echo ""
}

print_step() {
    echo "${BOLD}${BLUE}==>${RESET}${BOLD} $1${RESET}"
}

print_success() {
    echo "${GREEN}✓${RESET} $1"
}

print_info() {
    echo "  $1"
}

print_error() {
    echo "${RED}✗${RESET} $1" >&2
}

# =============================================================================
# Removal Functions
# =============================================================================

remove_binary() {
    print_step "Removing iTerm-PRISM executable"

    local prism_path="${INSTALL_DIR}/${SCRIPT_NAME}"

    if [[ ! -f "$prism_path" ]]; then
        print_info "Not installed at $prism_path"
        return 0
    fi

    rm "$prism_path"
    print_success "Removed $prism_path"
}

clean_cache() {
    print_step "Cleaning cache files"

    local count=0

    # Use a glob that won't error if no files match
    for file in "${HOME}"/.prism_preset_*; do
        if [[ -f "$file" ]]; then
            rm "$file"
            ((count++))
        fi
    done

    if [[ $count -gt 0 ]]; then
        print_success "Removed $count cache file(s)"
    else
        print_info "No cache files found"
    fi
}

remove_path_entry() {
    print_step "PATH entry cleanup"

    echo ""
    echo "Remove ${INSTALL_DIR} from shell profile?"
    read -p "(y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Kept PATH entry"
        return 0
    fi

    # Find and remove from shell profiles
    for profile in "${SHELL_PROFILES[@]}"; do
        if [[ -f "$profile" ]] && grep -q ".local/bin" "$profile" 2>/dev/null; then
            # Create backup
            cp "$profile" "${profile}.backup"

            # Remove iTerm-PRISM-added lines
            sed -i.bak '/# Added by iTerm-PRISM installer/d' "$profile"
            sed -i.bak '/export PATH=.*\.local\/bin/d' "$profile"

            # Clean up sed backup files
            rm -f "${profile}.bak"

            print_success "Removed from $profile (backup: ${profile}.backup)"
        fi
    done
}

remove_iterm2_package() {
    print_step "Python package cleanup"

    if ! pip3 show iterm2 >/dev/null 2>&1; then
        print_info "iterm2 package not installed"
        return 0
    fi

    echo ""
    echo "Remove iterm2 Python package?"
    echo "(This may affect other scripts using iTerm2 API)"
    read -p "(y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Kept iterm2 package"
        return 0
    fi

    pip3 uninstall -y iterm2 >/dev/null 2>&1
    print_success "Removed iterm2 package"
}

# =============================================================================
# Main
# =============================================================================

main() {
    setup_colors
    print_banner

    # Confirmation
    echo "${BOLD}This will remove iTerm-PRISM from your system.${RESET}"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    remove_binary
    echo ""

    clean_cache
    echo ""

    remove_path_entry
    echo ""

    remove_iterm2_package
    echo ""

    echo "${GREEN}${BOLD}Uninstall complete!${RESET}"
    echo ""
    echo "To reinstall iTerm-PRISM, run:"
    echo ""
    echo "  ${CYAN}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/USER/iTerm-PRISM/main/install.sh)\"${RESET}"
    echo ""
}

main "$@"
