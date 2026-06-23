#!/usr/bin/env bash
#
# iTerm-PRISM Installer
# Homebrew-style installation for iTerm2 color preset manager
#
# Usage:
#   Local mode (developers):  ./install.sh
#   Remote mode (end users):  /bin/bash -c "$(curl -fsSL https://...install.sh)"
#

set -e
set -u
set -o pipefail

# Configuration
INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_NAME="prism"
REQUIRED_PACKAGE="iterm2"

# Detect execution mode (local vs remote)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || echo "")"
if [[ -n "$SCRIPT_DIR" && -f "${SCRIPT_DIR}/prism" ]]; then
    MODE="local"
    SOURCE_SCRIPT="${SCRIPT_DIR}/prism"
    PRISM_DOWNLOAD_URL=""
else
    MODE="remote"
    SOURCE_SCRIPT=""
    # Update this URL when published to GitHub
    PRISM_DOWNLOAD_URL="https://raw.githubusercontent.com/USER/iTerm-PRISM/main/prism"
fi

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
    cat <<EOF

${BOLD}${CYAN}╔════════════════════════════════════════╗${RESET}
${BOLD}${CYAN}║                                        ║${RESET}
${BOLD}${CYAN}║        iTerm-PRISM Installer           ║${RESET}
${BOLD}${CYAN}║     Preset Rendering Iterm             ║${RESET}
${BOLD}${CYAN}║       Session Manager for iTerm2       ║${RESET}
${BOLD}${CYAN}║                                        ║${RESET}
${BOLD}${CYAN}╚════════════════════════════════════════╝${RESET}

EOF
}

print_step() {
    echo "${BOLD}${BLUE}==>${RESET}${BOLD} $1${RESET}"
}

print_success() {
    echo "${GREEN}✓${RESET} $1"
}

print_warning() {
    echo "${YELLOW}⚠${RESET}  $1"
}

print_error() {
    echo "${RED}✗${RESET} $1" >&2
}

print_info() {
    echo "  $1"
}

# =============================================================================
# Prerequisite Checks
# =============================================================================

check_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        print_error "iTerm-PRISM requires macOS (detected: $(uname -s))"
        return 1
    fi
    print_success "macOS detected"
}

check_python() {
    if ! command -v python3 >/dev/null 2>&1; then
        print_error "python3 not found"
        print_info "Install Python from https://www.python.org"
        return 1
    fi

    local version
    version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')

    if ! python3 -c "import sys; sys.exit(0 if tuple(map(int, '$version'.split('.'))) >= tuple(map(int, '3.7'.split('.'))) else 1)" 2>/dev/null; then
        print_error "Python 3.7+ required (found: $version)"
        return 1
    fi

    print_success "Python $version detected"
}

check_pip() {
    if ! command -v pip3 >/dev/null 2>&1; then
        print_error "pip3 not found"
        print_info "Install with: python3 -m ensurepip --upgrade"
        return 1
    fi
    print_success "pip3 available"
}

check_iterm2() {
    if [[ ! -d "/Applications/iTerm.app" ]]; then
        print_error "iTerm2 not detected at /Applications/iTerm.app"
        print_info "iTerm-PRISM requires iTerm2: https://iterm2.com"
        return 1
    fi
    print_success "iTerm2 detected"
}

# =============================================================================
# Download iTerm-PRISM (Remote Mode Only)
# =============================================================================

download_prism() {
    print_step "Downloading iTerm-PRISM script"

    if [[ -z "$PRISM_DOWNLOAD_URL" ]]; then
        print_error "Download URL not configured"
        return 1
    fi

    # Create temp directory
    local temp_dir
    temp_dir=$(mktemp -d)
    SOURCE_SCRIPT="${temp_dir}/prism"

    print_info "From: $PRISM_DOWNLOAD_URL"

    # Download script
    if ! curl -fsSL "$PRISM_DOWNLOAD_URL" -o "$SOURCE_SCRIPT" 2>/dev/null; then
        print_error "Failed to download iTerm-PRISM script"
        rm -rf "$temp_dir"
        return 1
    fi

    # Verify download
    if [[ ! -f "$SOURCE_SCRIPT" ]]; then
        print_error "Download verification failed"
        rm -rf "$temp_dir"
        return 1
    fi

    # Register cleanup on exit
    trap "rm -rf $temp_dir" EXIT

    print_success "iTerm-PRISM script downloaded"
}

# =============================================================================
# Install Dependencies
# =============================================================================

install_iterm2_package() {
    print_step "Installing Python dependencies"

    # Check if already installed
    if pip3 show iterm2 >/dev/null 2>&1; then
        local installed_version
        installed_version=$(pip3 show iterm2 | grep Version | awk '{print $2}')
        print_info "iterm2 package already installed (version $installed_version)"
        return 0
    fi

    print_info "Installing iterm2 package via pip3..."
    if ! pip3 install --user iterm2 >/dev/null 2>&1; then
        print_error "Failed to install iterm2 package"
        print_info "Try manually: pip3 install --user iterm2"
        return 1
    fi

    print_success "iterm2 package installed"
}

# =============================================================================
# Install Binary
# =============================================================================

install_prism() {
    print_step "Installing iTerm-PRISM executable"

    # Verify source exists
    if [[ ! -f "$SOURCE_SCRIPT" ]]; then
        print_error "Source script not found: $SOURCE_SCRIPT"
        return 1
    fi

    # Create install directory
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_info "Creating directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi

    # Check if already installed
    local dest="${INSTALL_DIR}/${SCRIPT_NAME}"
    if [[ -f "$dest" ]]; then
        print_warning "iTerm-PRISM already installed at $dest"
        echo ""
        read -p "Overwrite? (y/N): " -n 1 -r
        echo ""

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation skipped"
            return 0
        fi
    fi

    # Copy and make executable
    cp "$SOURCE_SCRIPT" "$dest"
    chmod +x "$dest"

    print_success "Installed to $dest"
}

# =============================================================================
# Configure PATH
# =============================================================================

configure_path() {
    print_step "Configuring PATH"

    # Find the appropriate shell profile
    local profile=""
    for candidate in "${SHELL_PROFILES[@]}"; do
        if [[ -f "$candidate" ]]; then
            profile="$candidate"
            break
        fi
    done

    if [[ -z "$profile" ]]; then
        print_warning "No shell profile found"
        print_manual_path_instructions
        return 0
    fi

    print_info "Shell profile detected: $profile"

    # Check if PATH line already exists in profile (most reliable check)
    if grep -q "export PATH=.*${INSTALL_DIR}" "$profile"; then
        print_success "${INSTALL_DIR} already configured in $profile"

        # Warn if multiple entries exist
        local entry_count
        entry_count=$(grep -c "export PATH=.*${INSTALL_DIR}" "$profile" || echo 0)
        if [[ $entry_count -gt 1 ]]; then
            print_warning "Multiple PATH entries detected ($entry_count found)"
            print_info "Consider cleaning up duplicate entries in $profile"
        fi

        return 0
    fi

    # Also check if already in current PATH
    if echo "$PATH" | grep -q ":${INSTALL_DIR}:" || echo "$PATH" | grep -q "^${INSTALL_DIR}:"; then
        print_warning "PATH entry exists but not in profile - may need to reload shell"
        print_info "Run: ${BOLD}source $profile${RESET}"
        return 0
    fi

    # Ask for confirmation before modifying
    echo ""
    echo "Add ${INSTALL_DIR} to PATH in $profile?"
    echo "This will append the following line:"
    echo ""
    echo "${CYAN}export PATH=\"\${HOME}/.local/bin:\$PATH\"${RESET}"
    echo ""
    read -p "Proceed? (Y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "Skipped PATH configuration"
        print_manual_path_instructions
        return 0
    fi

    # Add to shell profile
    echo "" >> "$profile"
    echo "# Added by iTerm-PRISM installer" >> "$profile"
    echo "export PATH=\"\${HOME}/.local/bin:\$PATH\"" >> "$profile"

    print_success "Added to $profile"
    print_info "Run: ${BOLD}source $profile${RESET} to activate"
}

print_manual_path_instructions() {
    cat <<EOF

${BOLD}Manual PATH Configuration:${RESET}

Add this line to your shell profile (~/.bash_profile or ~/.zshrc):

    ${CYAN}export PATH="\${HOME}/.local/bin:\$PATH"${RESET}

Then reload your shell:

    ${CYAN}source ~/.bash_profile${RESET}

EOF
}

# =============================================================================
# Verify Installation
# =============================================================================

verify_installation() {
    print_step "Verifying installation"

    local prism_path="${INSTALL_DIR}/${SCRIPT_NAME}"

    # Check file exists
    if [[ ! -f "$prism_path" ]]; then
        print_error "Binary not found at $prism_path"
        return 1
    fi

    # Check executable
    if [[ ! -x "$prism_path" ]]; then
        print_error "Binary not executable"
        return 1
    fi

    # Test execution (may fail if not in iTerm2, which is fine)
    if "$prism_path" --help >/dev/null 2>&1; then
        print_success "Installation verified"
    else
        print_warning "Binary exists but --help test inconclusive"
        print_info "This is normal if not running in iTerm2"
    fi
}

# =============================================================================
# Success Message
# =============================================================================

print_completion() {
    cat <<EOF

${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗
║                                                            ║
║  ✓ iTerm-PRISM installed successfully!                    ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝${RESET}

${BOLD}Next Steps:${RESET}

1. Reload your shell configuration:

   ${CYAN}source ~/.bash_profile${RESET}

2. Verify iTerm-PRISM is accessible:

   ${CYAN}prism --help${RESET}

3. Try it out:

   ${CYAN}prism --list${RESET}              # List all color presets
   ${CYAN}prism --set Andromeda${RESET}     # Set a specific preset
   ${CYAN}prism --next${RESET}              # Rotate to next preset
   ${CYAN}prism --sample${RESET}            # View all presets with colors

${BOLD}Documentation:${RESET}

   Full guide: https://github.com/USER/iTerm-PRISM#readme

${BOLD}Uninstall:${RESET}

   Run: ${CYAN}~/.local/bin/uninstall.sh${RESET}

EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
    setup_colors
    print_banner

    print_info "Installation mode: ${BOLD}$MODE${RESET}"
    echo ""

    # Prerequisite checks
    print_step "Checking prerequisites"
    check_macos || exit 1
    check_python || exit 1
    check_pip || exit 1
    check_iterm2 || exit 1
    echo ""

    # Download if remote mode
    if [[ "$MODE" == "remote" ]]; then
        download_prism || exit 1
        echo ""
    fi

    # Install dependencies
    install_iterm2_package || exit 1
    echo ""

    # Install binary
    install_prism || exit 1
    echo ""

    # Configure PATH
    configure_path
    echo ""

    # Verify
    verify_installation || exit 1
    echo ""

    # Success
    print_completion
}

main "$@"
