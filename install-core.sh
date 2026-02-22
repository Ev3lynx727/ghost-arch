#!/bin/bash

# Ghostarch Core Installation Script
# First-time setup: zsh, oh-my-zsh, BlackArch repository
# Run this once after fresh Arch Linux WSL2 installation

set -euo pipefail

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

# Source common library
if [[ -f "${PROJECT_ROOT}/lib/common.sh" ]]; then
    source "${PROJECT_ROOT}/lib/common.sh"
else
    echo "Error: Could not find ${PROJECT_ROOT}/lib/common.sh"
    exit 1
fi

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
        -n|--noninteractive) export NONINTERACTIVE=1 ;;
        -d|--debug) export DEBUG=1 ;;
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
    
    if [[ "$SKIP_ZSH" != "true" ]] || [[ "$SKIP_OMZ" != "true" ]]; then
        check_network || exit 1
    fi
    
    check_sudo
    load_config
    
    log_info "=== System Update ==="
    update_system
    
    if [[ "$SKIP_ZSH" != "true" ]]; then
        log_info "=== Installing Zsh ==="
        install_packages zsh
    fi
    
    if [[ "$SKIP_OMZ" != "true" ]]; then
        log_info "=== Installing Oh-My-Zsh ==="
        
        if [[ -d "$HOME/.oh-my-zsh" ]]; then
            log_warn "Oh-My-Zsh already installed, skipping..."
        else
            log_info "Cloning Oh-My-Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || log_warn "Oh-My-Zsh installation failed"
        fi
        
        log_info "Installing Oh-My-Zsh plugins..."
        local omz_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
        if [[ ! -d "${omz_custom}/plugins/zsh-autosuggestions" ]]; then
             git clone https://github.com/zsh-users/zsh-autosuggestions "${omz_custom}/plugins/zsh-autosuggestions" 2>/dev/null || true
        fi
        if [[ ! -d "${omz_custom}/plugins/zsh-syntax-highlighting" ]]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting "${omz_custom}/plugins/zsh-syntax-highlighting" 2>/dev/null || true
        fi
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
