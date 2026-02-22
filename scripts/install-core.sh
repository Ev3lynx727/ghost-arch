#!/bin/bash

# Ghostarch Core Installation Script
# First-time setup: zsh, oh-my-zsh, BlackArch repository
# Run this once after fresh Arch Linux WSL2 installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Ghostarch Core Installation - First-time setup

OPTIONS:
    -h, --help              Show this help message
    -n, --noninteractive   Run in non-interactive mode
    -d, --debug            Enable debug output
    --skip-zsh             Skip zsh installation
    --skip-omz             Skip oh-my-zsh installation
    --skip-blackarch       Skip BlackArch repository

EXAMPLES:
    $0                      # Interactive installation
    $0 --noninteractive     # Non-interactive installation
    $0 --skip-blackarch    # Skip BlackArch (already added)

EOF
    exit 0
}

SKIP_ZSH=false
SKIP_OMZ=false
SKIP_BLACKARCH=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -n|--noninteractive) NONINTERACTIVE=1 ;;
        -d|--debug) DEBUG=1 ;;
        --skip-zsh) SKIP_ZSH=true ;;
        --skip-omz) SKIP_OMZ=true ;;
        --skip-blackarch) SKIP_BLACKARCH=true ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

main() {
    init_logging
    
    log_info "Starting Ghostarch Core Installation"
    
    check_root
    check_wsl
    
    load_config
    
    [[ "${INSTALL_ZSH:-true}" != "true" ]] && SKIP_ZSH=true
    [[ "${INSTALL_OHMYZSH:-true}" != "true" ]] && SKIP_OMZ=true
    [[ "${INSTALL_BLACKARCH:-true}" != "true" ]] && SKIP_BLACKARCH=true
    
    if [[ "$SKIP_ZSH" != "true" ]] && [[ "$SKIP_OMZ" != "true" ]]; then
        check_network || exit 1
    fi
    
    check_sudo
    
    log_info "=== System Update ==="
    update_system
    
    if [[ "$SKIP_ZSH" != "true" ]]; then
        log_info "=== Installing Zsh ==="
        install_packages zsh
        
        log_info "Setting zsh as default shell..."
        chsh -s /bin/zsh || log_warn "Failed to set zsh as default shell"
    fi
    
    if [[ "$SKIP_OMZ" != "true" ]]; then
        log_info "=== Installing Oh-My-Zsh ==="
        
        if [[ -d "$HOME/.oh-my-zsh" ]]; then
            log_warn "Oh-My-Zsh already installed, skipping..."
        else
            log_info "Installing Oh-My-Zsh (vendored)..."
            source "${SCRIPT_DIR}/../vendors/oh-my-zsh-install.sh"
            install_ohmyzsh
            setup_ohmyzsh_unattended
        fi
        
        log_info "Installing Oh-My-Zsh plugins..."
        source "${SCRIPT_DIR}/../vendors/oh-my-zsh-install.sh"
        install_ohmyzsh_plugins
    fi
    
    log_info "=== Ghostarch Repository ==="
    log_info "Using local repository at ${SCRIPT_DIR}"
    
    if [[ ! -d "${SCRIPT_DIR}/.git" ]]; then
        log_warn "Not a git repository - skipping git operations"
    else
        log_info "Git repository detected"
    fi
    
    if [[ "$SKIP_BLACKARCH" != "true" ]]; then
        log_info "=== Adding BlackArch Repository ==="
        add_blackarch_repo
    else
        log_warn "Skipping BlackArch repository setup"
    fi
    
    log_info "=== Core Installation Complete ==="
    echo
    echo "Next steps:"
    echo "  1. Run ./install-tools.sh to install tools and configure user"
    echo "  2. Optionally run ./install-nvidia.sh for GPU acceleration"
    echo
}

main "$@"
